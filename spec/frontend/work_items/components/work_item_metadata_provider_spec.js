import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemMetadataProvider from '~/work_items/components/work_item_metadata_provider.vue';
import workItemMetadataQuery from 'ee_else_ce/work_items/graphql/work_item_metadata.query.graphql';
import workItemTypesConfigurationQuery from '~/work_items/graphql/work_item_types_configuration.query.graphql';
import { mockMetadataQueryResponse, mockWorkItemTypesConfigurationResponse } from '../mock_data';

Vue.use(VueApollo);

const defaultMetadataQueryHandler = jest.fn().mockResolvedValue(mockMetadataQueryResponse);
const defaultWorkItemTypesConfigurationHandler = jest
  .fn()
  .mockResolvedValue(mockWorkItemTypesConfigurationResponse);

describe('WorkItemMetadataProvider', () => {
  let wrapper;
  let metadataQueryHandler;
  let workItemTypesConfigurationHandler;

  const SlottedStub = {
    name: 'SlottedStub',
    // maxAttachmentSize is provided after the query resolves for the metadata
    // getWorkItemTypeConfiguration is our full work item config object utility
    inject: ['maxAttachmentSize', 'getWorkItemTypeConfiguration'],
    template: `
        <div class="slotted-stub">
          <span class="metadata-slot">{{ maxAttachmentSize }}</span>
          <span class="work-item-config">{{ getWorkItemTypeConfiguration('Issue') }}</span>
        </div>
      `,
  };

  const createComponent = ({
    metadataQueryHandlerParam = defaultMetadataQueryHandler,
    workItemTypesConfigurationHandlerParam = defaultWorkItemTypesConfigurationHandler,
    props = {},
  } = {}) => {
    workItemTypesConfigurationHandler = workItemTypesConfigurationHandlerParam;
    metadataQueryHandler = metadataQueryHandlerParam;

    const handler = workItemTypesConfigurationHandler;
    wrapper = mount(WorkItemMetadataProvider, {
      apolloProvider: createMockApollo([
        [workItemMetadataQuery, metadataQueryHandler],
        [workItemTypesConfigurationQuery, handler],
      ]),
      propsData: {
        fullPath: 'my-group',
        ...props,
      },
      slots: {
        default: SlottedStub,
      },
    });

    return waitForPromises();
  };

  const findSlotContent = () => wrapper.find('.slotted-stub');
  const findMetadataSlot = () => wrapper.find('.metadata-slot');
  const findWorkItemConfigSlot = () => wrapper.find('.work-item-config');

  beforeEach(async () => {
    await createComponent();
  });

  describe('component mounting', () => {
    it('renders the default slot', () => {
      expect(findSlotContent().exists()).toBe(true);
    });

    describe('Apollo queries', () => {
      describe('metadata query', () => {
        it('fetches the metadata', () => {
          expect(metadataQueryHandler).toHaveBeenCalledWith({
            fullPath: 'my-group',
          });
        });

        it('adds the metadata as reactive provide properties', async () => {
          expect(findMetadataSlot().html()).toContain('262144000');
          expect(findMetadataSlot().html()).not.toContain('1234');

          // We get another query result with a different value and assert the HTML has changed
          metadataQueryHandler.mockResolvedValue({
            ...mockMetadataQueryResponse,
            data: {
              ...mockMetadataQueryResponse.data,
              namespace: {
                ...mockMetadataQueryResponse.data.namespace,
                metadata: {
                  ...mockMetadataQueryResponse.data.namespace.metadata,
                  maxAttachmentSize: 1234,
                },
              },
            },
          });

          // Trigger the query to re-fire with a new variable fullPath value
          wrapper.setProps({ fullPath: '/new-path' });

          await waitForPromises();

          expect(metadataQueryHandler).toHaveBeenCalledTimes(2);
          expect(findMetadataSlot().html()).toContain('1234');
        });
      });

      describe('work item config', () => {
        it('fetched the work item type config', () => {
          expect(workItemTypesConfigurationHandler).toHaveBeenCalledWith({
            fullPath: 'my-group',
          });
        });

        it('data is passed to children and reactive', async () => {
          expect(findWorkItemConfigSlot().html()).toContain('widgetDefinitions');
          expect(findWorkItemConfigSlot().html()).toContain('"isServiceDesk": false');

          expect(findWorkItemConfigSlot().html()).not.toContain('"isServiceDesk": true');

          // We get another query result with a different value and assert the HTML has changed
          workItemTypesConfigurationHandler.mockResolvedValue({
            ...mockWorkItemTypesConfigurationResponse,
            data: {
              ...mockWorkItemTypesConfigurationResponse.data,
              namespace: {
                ...mockWorkItemTypesConfigurationResponse.data.namespace,
                workItemTypes: {
                  ...mockWorkItemTypesConfigurationResponse.data.namespace.workItemTypes,
                  nodes:
                    mockWorkItemTypesConfigurationResponse.data.namespace.workItemTypes.nodes.map(
                      (node) => (node.name === 'Issue' ? { ...node, isServiceDesk: true } : node),
                    ),
                },
              },
            },
          });

          // Trigger the query to re-fire with a new variable fullPath value
          wrapper.setProps({ fullPath: '/hello' });

          await waitForPromises();

          expect(workItemTypesConfigurationHandler).toHaveBeenCalledTimes(2);
          expect(findWorkItemConfigSlot().html()).toContain('"isServiceDesk": true');
        });
      });
    });
  });
});
