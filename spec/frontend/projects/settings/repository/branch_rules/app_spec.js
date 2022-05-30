import { mountExtended } from 'helpers/vue_test_utils_helper';
import BranchRules from '~/projects/settings/repository/branch_rules/app.vue';

describe('Branch rules app', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(BranchRules);
  };

  const findTitle = () => wrapper.find('strong');

  beforeEach(() => createComponent());

  it('renders a title', () => {
    expect(findTitle().text()).toBe('Branch');
  });
});
