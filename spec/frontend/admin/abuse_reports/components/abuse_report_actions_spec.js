import { mount, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { GlButton, GlModal } from '@gitlab/ui';
import AbuseReportActions from '~/admin/abuse_reports/components/abuse_report_actions.vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { sprintf } from '~/locale';
import { ACTIONS_I18N } from '~/admin/abuse_reports/constants';
import { mockAbuseReports } from '../mock_data';

jest.mock('~/alert');

describe('AbuseReportActions', () => {
  let wrapper;

  const findRemoveUserAndReportButton = () => wrapper.findAllComponents(GlButton).at(0);
  const findBlockUserButton = () => wrapper.findAllComponents(GlButton).at(1);
  const findRemoveReportButton = () => wrapper.findAllComponents(GlButton).at(2);
  const findConfirmationModal = () => wrapper.findComponent(GlModal);

  const report = mockAbuseReports[0];

  const createComponent = ({ props, mountFn } = { props: {}, mountFn: mount }) => {
    wrapper = mountFn(AbuseReportActions, {
      propsData: {
        report,
        ...props,
      },
    });
  };
  const createShallowComponent = (props) => createComponent({ props, mountFn: shallowMount });

  describe('default', () => {
    beforeEach(() => {
      createShallowComponent();
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
      createShallowComponent({ report: { ...report, userBlocked: true } });

      const button = findBlockUserButton();
      expect(button.text()).toBe(ACTIONS_I18N.alreadyBlocked);
      expect(button.attributes('disabled')).toBe('true');
    });
  });

  describe('actions', () => {
    let axiosMock;

    useMockLocationHelper();

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

        expect(window.location.reload).toHaveBeenCalled();
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
        'when reponse JSON is $responseData',
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

        expect(window.location.reload).toHaveBeenCalled();
      });
    });
  });
});
