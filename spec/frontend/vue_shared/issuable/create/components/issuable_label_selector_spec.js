import { shallowMount } from '@vue/test-utils';
import {
  mockRegularLabel,
  mockScopedLabel,
} from 'jest/sidebar/components/labels/labels_select_widget/mock_data';
import IssuableLabelSelector from '~/vue_shared/issuable/create/components/issuable_label_selector.vue';
import LabelsSelect from '~/sidebar/components/labels/labels_select_widget/labels_select_root.vue';
import { VARIANT_EMBEDDED } from '~/sidebar/components/labels/labels_select_widget/constants';
import { WORKSPACE_PROJECT } from '~/issues/constants';

const allowLabelRemove = true;
const attrWorkspacePath = '/workspace-path';
const fieldName = 'field_name[]';
const fullPath = '/full-path';
const labelsFilterBasePath = '/labels-filter-base-path';
const initialLabels = [];
const issuableType = 'issue';
const issuableSupportsLockOnMerge = false;
const labelType = WORKSPACE_PROJECT;
const variant = VARIANT_EMBEDDED;
const workspaceType = WORKSPACE_PROJECT;

describe('IssuableLabelSelector', () => {
  let wrapper;

  const findAllHiddenInputs = () => wrapper.findAll('input[type="hidden"]');
  const findLabelSelector = () => wrapper.findComponent(LabelsSelect);

  const createComponent = (injectedProps = {}) => {
    return shallowMount(IssuableLabelSelector, {
      provide: {
        allowLabelRemove,
        attrWorkspacePath,
        fieldName,
        fullPath,
        labelsFilterBasePath,
        initialLabels,
        issuableType,
        issuableSupportsLockOnMerge,
        labelType,
        variant,
        workspaceType,
        ...injectedProps,
      },
    });
  };

  describe('by default', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('has the label selector', () => {
      expect(findLabelSelector().props()).toMatchObject({
        allowLabelRemove,
        allowMultiselect: true,
        showEmbeddedLabelsList: true,
        fullPath,
        attrWorkspacePath,
        labelsFilterBasePath,
        dropdownButtonText: 'Select label',
        labelsListTitle: 'Select label',
        footerCreateLabelTitle: 'Create project label',
        footerManageLabelTitle: 'Manage project labels',
        variant,
        workspaceType,
        labelCreateType: labelType,
        selectedLabels: initialLabels,
      });

      expect(findLabelSelector().text()).toBe('None');
    });
  });

  it('passing initial labels applies them to the form', () => {
    wrapper = createComponent({ initialLabels: [mockRegularLabel, mockScopedLabel] });

    expect(findLabelSelector().props('selectedLabels')).toStrictEqual([
      mockRegularLabel,
      mockScopedLabel,
    ]);
    expect(findAllHiddenInputs().wrappers.map((input) => input.element.value)).toStrictEqual([
      `${mockRegularLabel.id}`,
      `${mockScopedLabel.id}`,
    ]);
  });

  it('updates the selected labels on the `updateSelectedLabels` event', async () => {
    wrapper = createComponent();

    expect(findLabelSelector().props('selectedLabels')).toStrictEqual([]);
    expect(findAllHiddenInputs()).toHaveLength(0);

    await findLabelSelector().vm.$emit('updateSelectedLabels', { labels: [mockRegularLabel] });

    expect(findLabelSelector().props('selectedLabels')).toStrictEqual([mockRegularLabel]);
    expect(findAllHiddenInputs().wrappers.map((input) => input.element.value)).toStrictEqual([
      `${mockRegularLabel.id}`,
    ]);
  });

  it('updates the selected labels on the `onLabelRemove` event', async () => {
    wrapper = createComponent({ initialLabels: [mockRegularLabel] });

    expect(findLabelSelector().props('selectedLabels')).toStrictEqual([mockRegularLabel]);
    expect(findAllHiddenInputs().wrappers.map((input) => input.element.value)).toStrictEqual([
      `${mockRegularLabel.id}`,
    ]);

    await findLabelSelector().vm.$emit('onLabelRemove', mockRegularLabel.id);

    expect(findLabelSelector().props('selectedLabels')).toStrictEqual([]);
    expect(findAllHiddenInputs()).toHaveLength(0);
  });
});
