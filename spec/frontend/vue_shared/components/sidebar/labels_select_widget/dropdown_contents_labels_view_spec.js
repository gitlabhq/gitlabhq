import { GlLoadingIcon, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { DropdownVariant } from '~/vue_shared/components/sidebar/labels_select_widget/constants';
import DropdownContentsLabelsView from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_contents_labels_view.vue';
import projectLabelsQuery from '~/vue_shared/components/sidebar/labels_select_widget/graphql/project_labels.query.graphql';
import LabelItem from '~/vue_shared/components/sidebar/labels_select_widget/label_item.vue';
import { mockConfig, labelsQueryResponse } from './mock_data';

jest.mock('~/flash');

const localVue = createLocalVue();
localVue.use(VueApollo);

const selectedLabels = [
  {
    id: 28,
    title: 'Bug',
    description: 'Label for bugs',
    color: '#FF0000',
    textColor: '#FFFFFF',
  },
];

describe('DropdownContentsLabelsView', () => {
  let wrapper;

  const successfulQueryHandler = jest.fn().mockResolvedValue(labelsQueryResponse);

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
        projectPath: 'test',
        iid: 1,
        allowLabelCreate: true,
        labelsManagePath: '/gitlab-org/my-project/-/labels',
        variant: DropdownVariant.Sidebar,
        ...injected,
      },
      propsData: {
        ...initialState,
        selectedLabels,
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
  const findDropdownWrapper = () => wrapper.find('[data-testid="dropdown-wrapper"]');
  const findDropdownFooter = () => wrapper.find('[data-testid="dropdown-footer"]');
  const findNoResultsMessage = () => wrapper.find('[data-testid="no-results"]');
  const findCreateLabelButton = () => wrapper.find('[data-testid="create-label-button"]');

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

    it('changes highlighted label correctly on pressing down button', async () => {
      expect(findLabels().at(0).attributes('highlight')).toBeUndefined();

      await findDropdownWrapper().trigger('keydown.down');
      expect(findLabels().at(0).attributes('highlight')).toBe('true');

      await findDropdownWrapper().trigger('keydown.down');
      expect(findLabels().at(1).attributes('highlight')).toBe('true');
      expect(findLabels().at(0).attributes('highlight')).toBeUndefined();
    });

    it('changes highlighted label correctly on pressing up button', async () => {
      await findDropdownWrapper().trigger('keydown.down');
      await findDropdownWrapper().trigger('keydown.down');
      expect(findLabels().at(1).attributes('highlight')).toBe('true');

      await findDropdownWrapper().trigger('keydown.up');
      expect(findLabels().at(0).attributes('highlight')).toBe('true');
    });

    it('changes label selected state when Enter is pressed', async () => {
      expect(findLabels().at(0).attributes('islabelset')).toBeUndefined();
      await findDropdownWrapper().trigger('keydown.down');
      await findDropdownWrapper().trigger('keydown.enter');

      expect(findLabels().at(0).attributes('islabelset')).toBe('true');
    });

    it('emits `closeDropdown event` when Esc button is pressed', () => {
      findDropdownWrapper().trigger('keydown.esc');

      expect(wrapper.emitted('closeDropdown')).toEqual([[selectedLabels]]);
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

  it('does not render footer on standalone dropdown', () => {
    createComponent({ injected: { variant: DropdownVariant.Standalone } });

    expect(findDropdownFooter().exists()).toBe(false);
  });

  it('renders footer on sidebar dropdown', () => {
    createComponent();

    expect(findDropdownFooter().exists()).toBe(true);
  });

  it('renders footer on embedded dropdown', () => {
    createComponent({ injected: { variant: DropdownVariant.Embedded } });

    expect(findDropdownFooter().exists()).toBe(true);
  });

  it('does not render create label button if `allowLabelCreate` is false', () => {
    createComponent({ injected: { allowLabelCreate: false } });

    expect(findCreateLabelButton().exists()).toBe(false);
  });

  describe('when `allowLabelCreate` is true', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders create label button', () => {
      expect(findCreateLabelButton().exists()).toBe(true);
    });

    it('emits `toggleDropdownContentsCreateView` event on create label button click', () => {
      findCreateLabelButton().vm.$emit('click');

      expect(wrapper.emitted('toggleDropdownContentsCreateView')).toEqual([[]]);
    });
  });
});
