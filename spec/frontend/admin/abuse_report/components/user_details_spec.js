import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
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
  const findPastReport = (index) => wrapper.findByTestId(`past-report-${index}`);

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
      expect(findUserDetailLabel('created-at')).toBe(USER_DETAILS_I18N.createdAt);
      expect(findTimeFor('created-at')).toBe(user.createdAt);
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
      expect(findUserDetailValue('verification')).toBe('Email, Phone, Credit card');
    });
  });

  describe('creditCard', () => {
    it('renders the correct label', () => {
      expect(findUserDetailLabel('credit-card-verification')).toBe(USER_DETAILS_I18N.creditCard);
    });

    describe('similar credit cards', () => {
      it('renders the number of similar records', () => {
        expect(findUserDetail('credit-card-verification').text()).toContain(
          `Card matches ${user.creditCard.similarRecordsCount} accounts`,
        );
      });

      it('renders a link to the matching cards', () => {
        expect(findLinkFor('credit-card-verification').attributes('href')).toBe(
          user.creditCard.cardMatchesLink,
        );

        expect(findLinkFor('credit-card-verification').text()).toBe(
          `${user.creditCard.similarRecordsCount} accounts`,
        );

        expect(findLinkFor('credit-card-verification').text()).toContain(
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
          expect(findUserDetail('credit-card-verification').text()).not.toContain(
            `Card matches ${user.creditCard.similarRecordsCount} accounts`,
          );
        });

        it('does not render a link to the matching cards', () => {
          expect(findLinkFor('credit-card-verification').exists()).toBe(false);
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
        expect(findUserDetail('credit-card-verification').exists()).toBe(false);
      });
    });
  });

  describe('phoneNumber', () => {
    it('renders the correct label', () => {
      expect(findUserDetailLabel('phone-number-verification')).toBe(USER_DETAILS_I18N.phoneNumber);
    });

    describe('similar phone numbers', () => {
      it('renders the number of similar records', () => {
        expect(findUserDetail('phone-number-verification').text()).toContain(
          `Phone matches ${user.phoneNumber.similarRecordsCount} accounts`,
        );
      });

      it('renders a link to the matching phone numbers', () => {
        expect(findLinkFor('phone-number-verification').attributes('href')).toBe(
          user.phoneNumber.phoneMatchesLink,
        );

        expect(findLinkFor('phone-number-verification').text()).toBe(
          `${user.phoneNumber.similarRecordsCount} accounts`,
        );
      });

      describe('when the number of similar phone numbers is less than 2', () => {
        beforeEach(() => {
          createComponent({
            user: { ...user, phoneNumber: { ...user.phoneNumber, similarRecordsCount: 1 } },
          });
        });

        it('does not render the number of similar records', () => {
          expect(findUserDetail('phone-number-verification').text()).not.toContain(
            `Phone matches ${user.phoneNumber.similarRecordsCount} accounts`,
          );
        });

        it('does not render a link to the matching phone numbers', () => {
          expect(findLinkFor('phone-number-verification').exists()).toBe(false);
        });
      });
    });

    describe('when the users phoneNumber is blank', () => {
      beforeEach(() => {
        createComponent({
          user: { ...user, phoneNumber: undefined },
        });
      });

      it('does not render the users phoneNumber', () => {
        expect(findUserDetail('phone-number-verification').exists()).toBe(false);
      });
    });
  });

  describe('otherReports', () => {
    it('renders the correct label', () => {
      expect(findUserDetailLabel('past-closed-reports')).toBe(USER_DETAILS_I18N.pastReports);
    });

    describe.each(user.pastClosedReports)('renders a line for report %#', (pastReport) => {
      const index = user.pastClosedReports.indexOf(pastReport);

      it('renders the category', () => {
        expect(findPastReport(index).text()).toContain(`Reported for ${pastReport.category}`);
      });

      it('renders a link to the report', () => {
        expect(findLinkIn(findPastReport(index)).attributes('href')).toBe(pastReport.reportPath);
      });

      it('renders the time it was created', () => {
        expect(findTimeIn(findPastReport(index))).toBe(pastReport.createdAt);
      });
    });

    describe('when the users otherReports is empty', () => {
      beforeEach(() => {
        createComponent({
          user: { ...user, pastClosedReports: [] },
        });
      });

      it('does not render the users otherReports', () => {
        expect(findUserDetail('past-closed-reports').exists()).toBe(false);
      });
    });
  });

  describe('normalLocation', () => {
    it('renders the correct label', () => {
      expect(findUserDetailLabel('normal-location')).toBe(USER_DETAILS_I18N.normalLocation);
    });

    describe('when the users mostUsedIp is blank', () => {
      it('renders the users lastSignInIp', () => {
        expect(findUserDetailValue('normal-location')).toBe(user.lastSignInIp);
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
        expect(findUserDetailValue('normal-location')).toBe(mostUsedIp);
      });
    });
  });

  describe('lastSignInIp', () => {
    it('renders the users lastSignInIp with the correct label', () => {
      expect(findUserDetailLabel('last-sign-in-ip')).toBe(USER_DETAILS_I18N.lastSignInIp);
      expect(findUserDetailValue('last-sign-in-ip')).toBe(user.lastSignInIp);
    });
  });

  it.each(['snippets', 'groups', 'notes'])(
    'renders the users %s with the correct label',
    (attribute) => {
      const testId = `user-${attribute}-count`;

      expect(findUserDetailLabel(testId)).toBe(USER_DETAILS_I18N[attribute]);
      expect(findUserDetailValue(testId)).toBe(
        USER_DETAILS_I18N[`${attribute}Count`](user[`${attribute}Count`]),
      );
    },
  );
});
