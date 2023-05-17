import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { sprintf } from '~/locale';
import UserDetails from '~/admin/abuse_report/components/user_details.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { USER_DETAILS_I18N } from '~/admin/abuse_report/constants';
import { mockAbuseReport } from '../mock_data';

describe('UserDetails', () => {
  let wrapper;

  const { user } = mockAbuseReport;

  const findUserDetail = (attribute) => wrapper.findByTestId(attribute);
  const findUserDetailLabel = (attribute) => findUserDetail(attribute).props('label');
  const findUserDetailValue = (attribute) => findUserDetail(attribute).props('value');
  const findLinkIn = (component) => component.findComponent(GlLink);
  const findLinkFor = (attribute) => findLinkIn(findUserDetail(attribute));
  const findTimeIn = (component) => component.findComponent(TimeAgoTooltip).props('time');
  const findTimeFor = (attribute) => findTimeIn(findUserDetail(attribute));
  const findOtherReport = (index) => wrapper.findByTestId(`other-report-${index}`);

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(UserDetails, {
      propsData: {
        user,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('createdAt', () => {
    it('renders the users createdAt with the correct label', () => {
      expect(findUserDetailLabel('createdAt')).toBe(USER_DETAILS_I18N.createdAt);
      expect(findTimeFor('createdAt')).toBe(user.createdAt);
    });
  });

  describe('email', () => {
    it('renders the users email with the correct label', () => {
      expect(findUserDetailLabel('email')).toBe(USER_DETAILS_I18N.email);
      expect(findLinkFor('email').attributes('href')).toBe(`mailto:${user.email}`);
      expect(findLinkFor('email').text()).toBe(user.email);
    });
  });

  describe('plan', () => {
    it('renders the users plan with the correct label', () => {
      expect(findUserDetailLabel('plan')).toBe(USER_DETAILS_I18N.plan);
      expect(findUserDetailValue('plan')).toBe(user.plan);
    });
  });

  describe('verification', () => {
    it('renders the users verification with the correct label', () => {
      expect(findUserDetailLabel('verification')).toBe(USER_DETAILS_I18N.verification);
      expect(findUserDetailValue('verification')).toBe('Email, Credit card');
    });
  });

  describe('creditCard', () => {
    it('renders the correct label', () => {
      expect(findUserDetailLabel('creditCard')).toBe(USER_DETAILS_I18N.creditCard);
    });

    it('renders the users name', () => {
      expect(findUserDetail('creditCard').text()).toContain(
        sprintf(USER_DETAILS_I18N.registeredWith, { ...user.creditCard }),
      );

      expect(findUserDetail('creditCard').text()).toContain(user.creditCard.name);
    });

    describe('similar credit cards', () => {
      it('renders the number of similar records', () => {
        expect(findUserDetail('creditCard').text()).toContain(
          sprintf('Card matches %{similarRecordsCount} accounts', { ...user.creditCard }),
        );
      });

      it('renders a link to the matching cards', () => {
        expect(findLinkFor('creditCard').attributes('href')).toBe(user.creditCard.cardMatchesLink);

        expect(findLinkFor('creditCard').text()).toBe(
          sprintf('%{similarRecordsCount} accounts', { ...user.creditCard }),
        );

        expect(findLinkFor('creditCard').text()).toContain(
          user.creditCard.similarRecordsCount.toString(),
        );
      });

      describe('when the number of similar credit cards is less than 2', () => {
        beforeEach(() => {
          createComponent({
            user: { ...user, creditCard: { ...user.creditCard, similarRecordsCount: 1 } },
          });
        });

        it('does not render the number of similar records', () => {
          expect(findUserDetail('creditCard').text()).not.toContain(
            sprintf('Card matches %{similarRecordsCount} accounts', { ...user.creditCard }),
          );
        });

        it('does not render a link to the matching cards', () => {
          expect(findLinkFor('creditCard').exists()).toBe(false);
        });
      });
    });

    describe('when the users creditCard is blank', () => {
      beforeEach(() => {
        createComponent({
          user: { ...user, creditCard: undefined },
        });
      });

      it('does not render the users creditCard', () => {
        expect(findUserDetail('creditCard').exists()).toBe(false);
      });
    });
  });

  describe('otherReports', () => {
    it('renders the correct label', () => {
      expect(findUserDetailLabel('otherReports')).toBe(USER_DETAILS_I18N.otherReports);
    });

    describe.each(user.otherReports)('renders a line for report %#', (otherReport) => {
      const index = user.otherReports.indexOf(otherReport);

      it('renders the category', () => {
        expect(findOtherReport(index).text()).toContain(
          sprintf('Reported for %{category}', { ...otherReport }),
        );
      });

      it('renders a link to the report', () => {
        expect(findLinkIn(findOtherReport(index)).attributes('href')).toBe(otherReport.reportPath);
      });

      it('renders the time it was created', () => {
        expect(findTimeIn(findOtherReport(index))).toBe(otherReport.createdAt);
      });
    });

    describe('when the users otherReports is empty', () => {
      beforeEach(() => {
        createComponent({
          user: { ...user, otherReports: [] },
        });
      });

      it('does not render the users otherReports', () => {
        expect(findUserDetail('otherReports').exists()).toBe(false);
      });
    });
  });

  describe('normalLocation', () => {
    it('renders the correct label', () => {
      expect(findUserDetailLabel('normalLocation')).toBe(USER_DETAILS_I18N.normalLocation);
    });

    describe('when the users mostUsedIp is blank', () => {
      it('renders the users lastSignInIp', () => {
        expect(findUserDetailValue('normalLocation')).toBe(user.lastSignInIp);
      });
    });

    describe('when the users mostUsedIp is not blank', () => {
      const mostUsedIp = '127.0.0.1';

      beforeEach(() => {
        createComponent({
          user: { ...user, mostUsedIp },
        });
      });

      it('renders the users mostUsedIp', () => {
        expect(findUserDetailValue('normalLocation')).toBe(mostUsedIp);
      });
    });
  });

  describe('lastSignInIp', () => {
    it('renders the users lastSignInIp with the correct label', () => {
      expect(findUserDetailLabel('lastSignInIp')).toBe(USER_DETAILS_I18N.lastSignInIp);
      expect(findUserDetailValue('lastSignInIp')).toBe(user.lastSignInIp);
    });
  });

  it.each(['snippets', 'groups', 'notes'])(
    'renders the users %s with the correct label',
    (attribute) => {
      expect(findUserDetailLabel(attribute)).toBe(USER_DETAILS_I18N[attribute]);
      expect(findUserDetailValue(attribute)).toBe(
        USER_DETAILS_I18N[`${attribute}Count`](user[`${attribute}Count`]),
      );
    },
  );
});
