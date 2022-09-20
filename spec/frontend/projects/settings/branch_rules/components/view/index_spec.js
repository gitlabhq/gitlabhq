import { getParameterByName } from '~/lib/utils/url_utility';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RuleView from '~/projects/settings/branch_rules/components/view/index.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterByName: jest.fn().mockImplementation(() => 'main'),
}));

describe('View branch rules', () => {
  let wrapper;
  const projectPath = 'test/testing';

  const createComponent = () => {
    wrapper = shallowMountExtended(RuleView, { propsData: { projectPath } });
  };

  beforeEach(() => createComponent());

  afterEach(() => wrapper.destroy());

  const findBranchName = () => wrapper.findByTestId('branch');

  it('gets the branch param from url and renders it in the view', () => {
    expect(getParameterByName).toHaveBeenCalledWith('branch');
    expect(findBranchName().text()).toBe('main');
  });
});
