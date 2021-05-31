import { GlLabel } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import {
  labels as TEST_LABELS,
  mockIssue as TEST_ISSUE,
  mockIssueFullPath as TEST_ISSUE_FULLPATH,
} from 'jest/boards/mock_data';
import BoardEditableItem from '~/boards/components/sidebar/board_editable_item.vue';
import BoardSidebarLabelsSelect from '~/boards/components/sidebar/board_sidebar_labels_select.vue';
import { createStore } from '~/boards/stores';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

const TEST_LABELS_PAYLOAD = TEST_LABELS.map((label) => ({ ...label, set: true }));
const TEST_LABELS_TITLES = TEST_LABELS.map((label) => label.title);

describe('~/boards/components/sidebar/board_sidebar_labels_select.vue', () => {
  let wrapper;
  let store;

  afterEach(() => {
    wrapper.destroy();
    store = null;
    wrapper = null;
  });

  const createWrapper = ({ labels = [], providedValues = {} } = {}) => {
    store = createStore();
    store.state.boardItems = { [TEST_ISSUE.id]: { ...TEST_ISSUE, labels } };
    store.state.activeId = TEST_ISSUE.id;

    wrapper = shallowMount(BoardSidebarLabelsSelect, {
      store,
      provide: {
        canUpdate: true,
        labelsManagePath: TEST_HOST,
        labelsFilterBasePath: TEST_HOST,
        ...providedValues,
      },
      stubs: {
        BoardEditableItem,
        LabelsSelect: true,
      },
    });
  };

  const findLabelsSelect = () => wrapper.find({ ref: 'labelsSelect' });
  const findLabelsTitles = () =>
    wrapper.findAll(GlLabel).wrappers.map((item) => item.props('title'));
  const findCollapsed = () => wrapper.find('[data-testid="collapsed-content"]');

  describe('when labelsFetchPath is provided', () => {
    it('uses injected labels fetch path', () => {
      createWrapper({ providedValues: { labelsFetchPath: 'foobar' } });

      expect(findLabelsSelect().props('labelsFetchPath')).toEqual('foobar');
    });
  });

  it('uses the default project label endpoint', () => {
    createWrapper();

    expect(findLabelsSelect().props('labelsFetchPath')).toEqual(
      `/${TEST_ISSUE_FULLPATH}/-/labels?include_ancestor_groups=true`,
    );
  });

  it('renders "None" when no labels are selected', () => {
    createWrapper();

    expect(findCollapsed().text()).toBe('None');
  });

  it('renders labels when set', () => {
    createWrapper({ labels: TEST_LABELS });

    expect(findLabelsTitles()).toEqual(TEST_LABELS_TITLES);
  });

  describe('when labels are submitted', () => {
    beforeEach(async () => {
      createWrapper();

      jest.spyOn(wrapper.vm, 'setActiveBoardItemLabels').mockImplementation(() => TEST_LABELS);
      findLabelsSelect().vm.$emit('updateSelectedLabels', TEST_LABELS_PAYLOAD);
      store.state.boardItems[TEST_ISSUE.id].labels = TEST_LABELS;
      await wrapper.vm.$nextTick();
    });

    it('collapses sidebar and renders labels', () => {
      expect(findCollapsed().isVisible()).toBe(true);
      expect(findLabelsTitles()).toEqual(TEST_LABELS_TITLES);
    });

    it('commits change to the server', () => {
      expect(wrapper.vm.setActiveBoardItemLabels).toHaveBeenCalledWith({
        addLabelIds: TEST_LABELS.map((label) => label.id),
        projectPath: TEST_ISSUE_FULLPATH,
        removeLabelIds: [],
      });
    });
  });

  describe('when labels are updated over existing labels', () => {
    const testLabelsPayload = [
      { id: 5, set: true },
      { id: 7, set: true },
    ];
    const expectedLabels = [{ id: 5 }, { id: 7 }];

    beforeEach(async () => {
      createWrapper({ labels: TEST_LABELS });

      jest.spyOn(wrapper.vm, 'setActiveBoardItemLabels').mockImplementation(() => expectedLabels);
      findLabelsSelect().vm.$emit('updateSelectedLabels', testLabelsPayload);
      await wrapper.vm.$nextTick();
    });

    it('commits change to the server', () => {
      expect(wrapper.vm.setActiveBoardItemLabels).toHaveBeenCalledWith({
        addLabelIds: [5, 7],
        removeLabelIds: [6],
        projectPath: TEST_ISSUE_FULLPATH,
      });
    });
  });

  describe('when removing individual labels', () => {
    const testLabel = TEST_LABELS[0];

    beforeEach(async () => {
      createWrapper({ labels: [testLabel] });

      jest.spyOn(wrapper.vm, 'setActiveBoardItemLabels').mockImplementation(() => {});
    });

    it('commits change to the server', () => {
      wrapper.find(GlLabel).vm.$emit('close', testLabel);

      expect(wrapper.vm.setActiveBoardItemLabels).toHaveBeenCalledWith({
        removeLabelIds: [getIdFromGraphQLId(testLabel.id)],
        projectPath: TEST_ISSUE_FULLPATH,
      });
    });
  });

  describe('when the mutation fails', () => {
    beforeEach(async () => {
      createWrapper({ labels: TEST_LABELS });

      jest.spyOn(wrapper.vm, 'setActiveBoardItemLabels').mockImplementation(() => {
        throw new Error(['failed mutation']);
      });
      jest.spyOn(wrapper.vm, 'setError').mockImplementation(() => {});
      findLabelsSelect().vm.$emit('updateSelectedLabels', [{ id: '?' }]);
      await wrapper.vm.$nextTick();
    });

    it('collapses sidebar and renders former issue weight', () => {
      expect(findCollapsed().isVisible()).toBe(true);
      expect(findLabelsTitles()).toEqual(TEST_LABELS_TITLES);
      expect(wrapper.vm.setError).toHaveBeenCalled();
    });
  });
});
