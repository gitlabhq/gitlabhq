import Vue from 'vue';
import { GlForm, GlFormCombobox } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemLinksForm from '~/work_items/components/work_item_links/work_item_links_form.vue';
import projectWorkItemsQuery from '~/work_items/graphql/project_work_items.query.graphql';
import { availableWorkItemsResponse } from '../../mock_data';

Vue.use(VueApollo);

describe('WorkItemLinksForm', () => {
  let wrapper;

  const createComponent = async ({ response = availableWorkItemsResponse } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinksForm, {
      apolloProvider: createMockApollo([
        [projectWorkItemsQuery, jest.fn().mockResolvedValue(response)],
      ]),
      propsData: { issuableId: 1 },
      provide: {
        projectPath: 'project/path',
      },
    });

    await waitForPromises();
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findCombobox = () => wrapper.findComponent(GlFormCombobox);

  beforeEach(async () => {
    await createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders form', () => {
    expect(findForm().exists()).toBe(true);
  });

  it('passes available work items as prop when typing in combobox', async () => {
    expect(findCombobox().exists()).toBe(true);
    expect(findCombobox().props('tokenList').length).toBe(2);
  });
});
