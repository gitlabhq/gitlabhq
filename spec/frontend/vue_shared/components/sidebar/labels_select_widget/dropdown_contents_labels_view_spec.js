import { GlLoadingIcon, GlSearchBoxByType, GlDropdownItem } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import { IssuableType } from '~/issue_show/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { DropdownVariant } from '~/vue_shared/components/sidebar/labels_select_widget/constants';
import DropdownContentsLabelsView from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_contents_labels_view.vue';
import projectLabelsQuery from '~/vue_shared/components/sidebar/labels_select_widget/graphql/project_labels.query.graphql';
import LabelItem from '~/vue_shared/components/sidebar/labels_select_widget/label_item.vue';
import { mockConfig, workspaceLabelsQueryResponse } from './mock_data';

jest.mock('~/flash');

const localVue = createLocalVue();
localVue.use(VueApollo);

const localSelectedLabels = [
  {
    color: '#2f7b2e',
    description: null,
    id: 'gid://gitlab/ProjectLabel/2',
    title: 'Label2',
  },
];

describe('DropdownContentsLabelsView', () => {
  let wrapper;

  const successfulQueryHandler = jest.fn().mockResolvedValue(workspaceLabelsQueryResponse);

  const findFirstLabel = () => wrapper.findAllComponents(GlDropdownItem).at(0);

  const createComponent = ({
    initialState = mockConfig,
    queryHandler = successfulQueryHandler,
    injected = {},
  } = {}) => {
    const mockApollo = createMockApollo([[projectLabelsQuery, queryHandler]]);

    wrapper = shallowMount(DropdownContentsLabelsView, {
      localVue,
      apolloProvider: mockApollo,
      provide: {
        fullPath: 'test',
        iid: 1,
        variant: DropdownVariant.Sidebar,
        ...injected,
      },
      propsData: {
        ...initialState,
        localSelectedLabels,
        issuableType: IssuableType.Issue,
      },
      stubs: {
        GlSearchBoxByType,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findSearchInput = () => wrapper.findComponent(GlSearchBoxByType);
  const findLabels = () => wrapper.findAllComponents(LabelItem);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const findLabelsList = () => wrapper.find('[data-testid="labels-list"]');
  const findNoResultsMessage = () => wrapper.find('[data-testid="no-results"]');

  describe('when loading labels', () => {
    it('renders disabled search input field', async () => {
      createComponent();
      expect(findSearchInput().props('disabled')).toBe(true);
    });

    it('renders loading icon', async () => {
      createComponent();
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render labels list', async () => {
      createComponent();
      expect(findLabelsList().exists()).toBe(false);
    });
  });

  describe('when labels are loaded', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders enabled search input field', async () => {
      expect(findSearchInput().props('disabled')).toBe(false);
    });

    it('does not render loading icon', async () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders labels list', async () => {
      expect(findLabelsList().exists()).toBe(true);
      expect(findLabels()).toHaveLength(2);
    });
  });

  it('when search returns 0 results', async () => {
    createComponent({
      queryHandler: jest.fn().mockResolvedValue({
        data: {
          workspace: {
            labels: {
              nodes: [],
            },
          },
        },
      }),
    });
    findSearchInput().vm.$emit('input', '123');
    await waitForPromises();
    await nextTick();

    expect(findNoResultsMessage().isVisible()).toBe(true);
  });

  it('calls `createFlash` when fetching labels failed', async () => {
    createComponent({ queryHandler: jest.fn().mockRejectedValue('Houston, we have a problem!') });
    jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    await waitForPromises();

    expect(createFlash).toHaveBeenCalled();
  });

  it('emits an `input` event on label click', async () => {
    createComponent();
    await waitForPromises();
    findFirstLabel().trigger('click');

    expect(wrapper.emitted('input')[0][0]).toEqual(expect.arrayContaining(localSelectedLabels));
  });
});
