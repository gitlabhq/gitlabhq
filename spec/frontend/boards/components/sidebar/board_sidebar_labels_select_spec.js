import { shallowMount } from '@vue/test-utils';
import { GlLabel } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import { labels as TEST_LABELS, mockIssue as TEST_ISSUE } from 'jest/boards/mock_data';
import BoardSidebarLabelsSelect from '~/boards/components/sidebar/board_sidebar_labels_select.vue';
import BoardEditableItem from '~/boards/components/sidebar/board_editable_item.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createStore } from '~/boards/stores';
import createFlash from '~/flash';

jest.mock('~/flash');

const TEST_LABELS_PAYLOAD = TEST_LABELS.map(label => ({ ...label, set: true }));
const TEST_LABELS_TITLES = TEST_LABELS.map(label => label.title);

describe('~/boards/components/sidebar/board_sidebar_labels_select.vue', () => {
  let wrapper;
  let store;

  afterEach(() => {
    wrapper.destroy();
    store = null;
    wrapper = null;
  });

  const createWrapper = ({ labels = [] } = {}) => {
    store = createStore();
    store.state.issues = { [TEST_ISSUE.id]: { ...TEST_ISSUE, labels } };
    store.state.activeId = TEST_ISSUE.id;

    wrapper = shallowMount(BoardSidebarLabelsSelect, {
      store,
      provide: {
        canUpdate: true,
        labelsFetchPath: TEST_HOST,
        labelsManagePath: TEST_HOST,
        labelsFilterBasePath: TEST_HOST,
      },
      stubs: {
        'board-editable-item': BoardEditableItem,
        'labels-select': '<div></div>',
      },
    });
  };

  const findLabelsSelect = () => wrapper.find({ ref: 'labelsSelect' });
  const findLabelsTitles = () => wrapper.findAll(GlLabel).wrappers.map(item => item.props('title'));
  const findCollapsed = () => wrapper.find('[data-testid="collapsed-content"]');

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

      jest.spyOn(wrapper.vm, 'setActiveIssueLabels').mockImplementation(() => TEST_LABELS);
      findLabelsSelect().vm.$emit('updateSelectedLabels', TEST_LABELS_PAYLOAD);
      store.state.issues[TEST_ISSUE.id].labels = TEST_LABELS;
      await wrapper.vm.$nextTick();
    });

    it('collapses sidebar and renders labels', () => {
      expect(findCollapsed().isVisible()).toBe(true);
      expect(findLabelsTitles()).toEqual(TEST_LABELS_TITLES);
    });

    it('commits change to the server', () => {
      expect(wrapper.vm.setActiveIssueLabels).toHaveBeenCalledWith({
        addLabelIds: TEST_LABELS.map(label => label.id),
        projectPath: 'gitlab-org/test-subgroup/gitlab-test',
        removeLabelIds: [],
      });
    });
  });

  describe('when labels are updated over existing labels', () => {
    const testLabelsPayload = [{ id: 5, set: true }, { id: 7, set: true }];
    const expectedLabels = [{ id: 5 }, { id: 7 }];

    beforeEach(async () => {
      createWrapper({ labels: TEST_LABELS });

      jest.spyOn(wrapper.vm, 'setActiveIssueLabels').mockImplementation(() => expectedLabels);
      findLabelsSelect().vm.$emit('updateSelectedLabels', testLabelsPayload);
      await wrapper.vm.$nextTick();
    });

    it('commits change to the server', () => {
      expect(wrapper.vm.setActiveIssueLabels).toHaveBeenCalledWith({
        addLabelIds: [5, 7],
        removeLabelIds: [6],
        projectPath: 'gitlab-org/test-subgroup/gitlab-test',
      });
    });
  });

  describe('when removing individual labels', () => {
    const testLabel = TEST_LABELS[0];

    beforeEach(async () => {
      createWrapper({ labels: [testLabel] });

      jest.spyOn(wrapper.vm, 'setActiveIssueLabels').mockImplementation(() => {});
    });

    it('commits change to the server', () => {
      wrapper.find(GlLabel).vm.$emit('close', testLabel);

      expect(wrapper.vm.setActiveIssueLabels).toHaveBeenCalledWith({
        removeLabelIds: [getIdFromGraphQLId(testLabel.id)],
        projectPath: 'gitlab-org/test-subgroup/gitlab-test',
      });
    });
  });

  describe('when the mutation fails', () => {
    beforeEach(async () => {
      createWrapper({ labels: TEST_LABELS });

      jest.spyOn(wrapper.vm, 'setActiveIssueLabels').mockImplementation(() => {
        throw new Error(['failed mutation']);
      });
      findLabelsSelect().vm.$emit('updateSelectedLabels', [{ id: '?' }]);
      await wrapper.vm.$nextTick();
    });

    it('collapses sidebar and renders former issue weight', () => {
      expect(findCollapsed().isVisible()).toBe(true);
      expect(findLabelsTitles()).toEqual(TEST_LABELS_TITLES);
      expect(createFlash).toHaveBeenCalled();
    });
  });
});
