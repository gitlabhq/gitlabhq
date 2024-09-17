import { nextTick } from 'vue';
import { GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import Protections, {
  i18n,
} from '~/projects/settings/branch_rules/components/edit/protections/index.vue';
import PushProtections from '~/projects/settings/branch_rules/components/edit/protections/push_protections.vue';
import MergeProtections from '~/projects/settings/branch_rules/components/edit/protections/merge_protections.vue';
import { protections } from '../../../mock_data';

describe('Branch Protections', () => {
  let wrapper;

  const createComponent = async () => {
    wrapper = mountExtended(Protections, {
      propsData: { protections },
    });
    await nextTick();
  };

  const findHeading = () => wrapper.find('h4');
  const findHelpText = () => wrapper.findByTestId('protections-help-text');
  const findHelpLink = () => wrapper.findComponent(GlLink);
  const findPushProtections = () => wrapper.findComponent(PushProtections);
  const findMergeProtections = () => wrapper.findComponent(MergeProtections);

  beforeEach(() => createComponent());

  it('renders a heading', () => {
    expect(findHeading().text()).toBe(i18n.protections);
  });

  it('renders help text', () => {
    expect(findHelpText().text()).toMatchInterpolatedText(i18n.protectionsHelpText);
    expect(findHelpLink().attributes('href')).toBe(
      '/help/user/project/repository/branches/protected',
    );
  });

  it('renders a PushProtections component with correct props', () => {
    expect(findPushProtections().props('membersAllowedToPush')).toStrictEqual(
      protections.membersAllowedToPush,
    );
    expect(findPushProtections().props('allowForcePush')).toBe(protections.allowForcePush);
  });

  it('renders a MergeProtections component with correct props', () => {
    expect(findMergeProtections().props('membersAllowedToMerge')).toStrictEqual(
      protections.membersAllowedToMerge,
    );
    expect(findMergeProtections().props('requireCodeOwnersApproval')).toBe(
      protections.requireCodeOwnersApproval,
    );
  });
});
