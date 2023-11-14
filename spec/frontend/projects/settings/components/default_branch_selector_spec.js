import { shallowMount } from '@vue/test-utils';
import DefaultBranchSelector from '~/projects/settings/components/default_branch_selector.vue';
import RefSelector from '~/ref/components/ref_selector.vue';
import { REF_TYPE_BRANCHES } from '~/ref/constants';

describe('projects/settings/components/default_branch_selector', () => {
  const disabled = true;
  const persistedDefaultBranch = 'main';
  const projectId = '123';
  let wrapper;

  const findRefSelector = () => wrapper.findComponent(RefSelector);

  const buildWrapper = () => {
    wrapper = shallowMount(DefaultBranchSelector, {
      propsData: {
        disabled,
        persistedDefaultBranch,
        projectId,
      },
    });
  };

  beforeEach(() => {
    buildWrapper();
  });

  it('displays a RefSelector component', () => {
    expect(findRefSelector().props()).toEqual({
      disabled,
      value: persistedDefaultBranch,
      enabledRefTypes: [REF_TYPE_BRANCHES],
      projectId,
      state: true,
      toggleButtonClass: null,
      translations: {
        dropdownHeader: expect.any(String),
        searchPlaceholder: expect.any(String),
      },
      useSymbolicRefNames: false,
      name: 'project[default_branch]',
    });

    expect(findRefSelector().classes()).toContain('gl-w-full');
  });
});
