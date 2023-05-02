import { nextTick } from 'vue';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AbuseReportActions from '~/admin/abuse_reports/components/abuse_report_actions.vue';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { redirectTo, refreshCurrentPage } from '~/lib/utils/url_utility';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { sprintf } from '~/locale';
import { ACTIONS_I18N } from '~/admin/abuse_reports/constants';
import { mockAbuseReports } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

describe('AbuseReportActions', () => {
  let wrapper;

  const findRemoveUserAndReportButton = () => wrapper.findByText('Remove user & report');
  const findBlockUserButton = () => wrapper.findByTestId('block-user-button');
  const findRemoveReportButton = () => wrapper.findByText('Remove report');
  const findConfirmationModal = () => wrapper.findComponent(GlModal);

  const report = mockAbuseReports[0];

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(AbuseReportActions, {
      propsData: {
        report,
        ...props,
      },
      stubs: {
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays "Block user", "Remove user & report", and "Remove report" buttons', () => {
      expect(findRemoveUserAndReportButton().text()).toBe(ACTIONS_I18N.removeUserAndReport);

      const blockButton = findBlockUserButton();
      expect(blockButton.text()).toBe(ACTIONS_I18N.blockUser);
      expect(blockButton.attributes('disabled')).toBeUndefined();

      expect(findRemoveReportButton().text()).toBe(ACTIONS_I18N.removeReport);
    });

    it('does not show the confirmation modal initially', () => {
      expect(findConfirmationModal().props('visible')).toBe(false);
    });
  });

  describe('block button when user is already blocked', () => {
    it('is disabled and has the correct text', () => {
      createComponent({ report: { ...report, userBlocked: true } });

      const button = findBlockUserButton();
      expect(button.text()).toBe(ACTIONS_I18N.alreadyBlocked);
      expect(button.attributes('disabled')).toBe('disabled');
    });
  });

  describe('actions', () => {
    let axiosMock;

    beforeEach(() => {
      axiosMock = new MockAdapter(axios);

      createComponent();
    });

    afterEach(() => {
      axiosMock.restore();
      createAlert.mockClear();
    });

    describe('on remove user and report', () => {
      it('shows confirmation modal and reloads the page on success', async () => {
        findRemoveUserAndReportButton().trigger('click');
        await nextTick();

        expect(findConfirmationModal().props()).toMatchObject({
          visible: true,
          title: sprintf(ACTIONS_I18N.removeUserAndReportConfirm, {
            user: report.reportedUser.name,
          }),
        });

        axiosMock.onDelete(report.removeUserAndReportPath).reply(HTTP_STATUS_OK);

        findConfirmationModal().vm.$emit('primary');
        await axios.waitForAll();

        expect(refreshCurrentPage).toHaveBeenCalled();
      });

      describe('when a redirect path is present', () => {
        beforeEach(() => {
          createComponent({ report: { ...report, redirectPath: '/redirect_path' } });
        });

        it('redirects to the given path', async () => {
          findRemoveUserAndReportButton().trigger('click');
          await nextTick();

          axiosMock.onDelete(report.removeUserAndReportPath).reply(HTTP_STATUS_OK);

          findConfirmationModal().vm.$emit('primary');
          await axios.waitForAll();

          expect(redirectTo).toHaveBeenCalledWith('/redirect_path');
        });
      });
    });

    describe('on block user', () => {
      beforeEach(async () => {
        findBlockUserButton().trigger('click');
        await nextTick();
      });

      it('shows confirmation modal', () => {
        expect(findConfirmationModal().props()).toMatchObject({
          visible: true,
          title: ACTIONS_I18N.blockUserConfirm,
        });
      });

      describe.each([
        {
          responseData: { notice: 'Notice' },
          createAlertArgs: { message: 'Notice', variant: VARIANT_SUCCESS },
          blockButtonText: ACTIONS_I18N.alreadyBlocked,
          blockButtonDisabled: 'disabled',
        },
        {
          responseData: { error: 'Error' },
          createAlertArgs: { message: 'Error' },
          blockButtonText: ACTIONS_I18N.blockUser,
          blockButtonDisabled: undefined,
        },
      ])(
        'when response JSON is $responseData',
        ({ responseData, createAlertArgs, blockButtonText, blockButtonDisabled }) => {
          beforeEach(async () => {
            axiosMock.onPut(report.blockUserPath).reply(HTTP_STATUS_OK, responseData);

            findConfirmationModal().vm.$emit('primary');
            await axios.waitForAll();
          });

          it('updates the block button correctly', () => {
            const button = findBlockUserButton();
            expect(button.text()).toBe(blockButtonText);
            expect(button.attributes('disabled')).toBe(blockButtonDisabled);
          });

          it('displays the returned message', () => {
            expect(createAlert).toHaveBeenCalledWith(createAlertArgs);
          });
        },
      );
    });

    describe('on remove report', () => {
      it('reloads the page on success', async () => {
        axiosMock.onDelete(report.removeReportPath).reply(HTTP_STATUS_OK);

        findRemoveReportButton().trigger('click');

        expect(findConfirmationModal().props('visible')).toBe(false);

        await axios.waitForAll();

        expect(refreshCurrentPage).toHaveBeenCalled();
      });

      describe('when a redirect path is present', () => {
        beforeEach(() => {
          createComponent({ report: { ...report, redirectPath: '/redirect_path' } });
        });

        it('redirects to the given path', async () => {
          axiosMock.onDelete(report.removeReportPath).reply(HTTP_STATUS_OK);

          findRemoveReportButton().trigger('click');

          await axios.waitForAll();

          expect(redirectTo).toHaveBeenCalledWith('/redirect_path');
        });
      });
    });
  });
});
