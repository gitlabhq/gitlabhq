import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import BranchRules, { i18n } from '~/projects/settings/repository/branch_rules/app.vue';
import branchRulesQuery from '~/projects/settings/repository/branch_rules/graphql/queries/branch_rules.query.graphql';
import createFlash from '~/flash';
import { branchRulesMockResponse, propsDataMock } from './mock_data';

jest.mock('~/flash');

Vue.use(VueApollo);

describe('Branch rules app', () => {
  let wrapper;
  let fakeApollo;

  const branchRulesQuerySuccessHandler = jest.fn().mockResolvedValue(branchRulesMockResponse);

  const createComponent = async (branchRulesQueryHandler = branchRulesQuerySuccessHandler) => {
    fakeApollo = createMockApollo([[branchRulesQuery, branchRulesQueryHandler]]);

    wrapper = mountExtended(BranchRules, {
      apolloProvider: fakeApollo,
      propsData: {
        ...propsDataMock,
      },
    });

    await waitForPromises();
  };

  const findTitle = () => wrapper.find('strong');

  beforeEach(() => createComponent());

  it('displays an error if branch rules query fails', async () => {
    await createComponent(jest.fn().mockRejectedValue());
    expect(createFlash).toHaveBeenCalledWith({ message: i18n.queryError });
  });

  it('renders a title', () => {
    expect(findTitle().text()).toBe(i18n.heading);
  });
});
