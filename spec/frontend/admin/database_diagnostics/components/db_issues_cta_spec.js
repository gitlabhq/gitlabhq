import { GlCard } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { helpPagePath } from '~/helpers/help_page_helper';
import { SUPPORT_URL } from '~/sessions/new/constants';
import DbIssuesCta from '~/admin/database_diagnostics/components/db_issues_cta.vue';

describe('DbIssuesCta component', () => {
  let wrapper;

  const findLearnMoreButton = () => wrapper.findByTestId('learn-more-button');
  const findContactSupportButton = () => wrapper.findByTestId('contact-support-button');

  const createComponent = () => {
    wrapper = shallowMountExtended(DbIssuesCta, {
      stubs: { GlCard },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('displays a message about manual remediation', () => {
    expect(wrapper.text()).toContain('These issues require manual remediation.');
  });

  it('provides properly configured buttons for getting help', () => {
    const learnMoreButton = findLearnMoreButton();
    expect(learnMoreButton.text()).toBe('Learn more');
    expect(learnMoreButton.attributes()).toMatchObject({
      href: helpPagePath('administration/postgresql/upgrading_os'),
    });

    const contactSupportButton = findContactSupportButton();
    expect(contactSupportButton.text()).toBe('Contact Support');
    expect(contactSupportButton.attributes()).toMatchObject({
      href: SUPPORT_URL,
    });
  });

  it('displays a title indicating issues were detected', () => {
    expect(wrapper.text()).toContain('Issues detected');
    expect(wrapper.text()).toContain('These issues require manual remediation.');
  });
});
