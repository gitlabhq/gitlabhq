import MockAdapter from 'axios-mock-adapter';
import { GlDrawer } from '@gitlab/ui';
import { nextTick } from 'vue';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_OK,
  HTTP_STATUS_UNPROCESSABLE_ENTITY,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
} from '~/lib/utils/http_status';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ReportActions from '~/admin/abuse_report/components/report_actions.vue';
import {
  ACTIONS_I18N,
  SUCCESS_ALERT,
  FAILED_ALERT,
  ERROR_MESSAGE,
  NO_ACTION,
  USER_ACTION_OPTIONS,
  TRUST_ACTION,
  TRUST_REASON,
  REASON_OPTIONS,
} from '~/admin/abuse_report/constants';
import { mockAbuseReport } from '../mock_data';

describe('ReportActions', () => {
  let wrapper;
  let axiosMock;

  const params = {
    user_action: 'ban_user',
    close: true,
    comment: 'my comment',
    reason: 'spam',
  };

  const { user, report } = mockAbuseReport;

  const clickActionsButton = () => wrapper.findByTestId('actions-button').vm.$emit('click');
  const isDrawerOpen = () => wrapper.findComponent(GlDrawer).props('open');
  const findErrorFor = (id) => wrapper.findByTestId(id).find('.d-block.invalid-feedback');
  const findUserActionOptions = () => wrapper.findByTestId('action-select');
  const setCloseReport = (close) => wrapper.findByTestId('close').find('input').setChecked(close);
  const setSelectOption = (id, value) =>
    wrapper.findByTestId(`${id}-select`).find(`option[value=${value}]`).setSelected();
  const selectAction = (chosenAction) => setSelectOption('action', chosenAction);
  const selectReason = (reason) => setSelectOption('reason', reason);
  const setComment = (comment) => wrapper.findByTestId('comment').find('input').setValue(comment);
  const submitForm = () => wrapper.findByTestId('submit-button').vm.$emit('click');
  const findReasonOptions = () => wrapper.findByTestId('reason-select');

  const createComponent = (props = {}) => {
    wrapper = mountExtended(ReportActions, {
      propsData: {
        user,
        report,
        ...props,
      },
    });
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    axiosMock.restore();
  });

  it('initially hides the drawer', () => {
    expect(isDrawerOpen()).toBe(false);
  });

  describe('actions', () => {
    describe('when logged in user is not the user being reported', () => {
      beforeEach(() => {
        clickActionsButton();
      });

      it('shows "No action", "Block user", "Ban user" and "Delete user" options', () => {
        const options = findUserActionOptions().findAll('option');

        expect(options).toHaveLength(USER_ACTION_OPTIONS.length);

        USER_ACTION_OPTIONS.forEach((userAction, index) => {
          expect(options.at(index).text()).toBe(userAction.text);
        });
      });
    });

    describe('when logged in user is the user being reported', () => {
      beforeEach(() => {
        gon.current_username = user.username;
        clickActionsButton();
      });

      it('only shows "No action" option', () => {
        const options = findUserActionOptions().findAll('option');

        expect(options).toHaveLength(1);
        expect(options.at(0).text()).toBe(NO_ACTION.text);
      });
    });
  });

  describe('reasons', () => {
    beforeEach(() => {
      clickActionsButton();
    });

    it('shows all non-trust reasons by default', () => {
      const reasons = findReasonOptions().findAll('option');
      expect(reasons).toHaveLength(REASON_OPTIONS.length);

      REASON_OPTIONS.forEach((reason, index) => {
        expect(reasons.at(index).text()).toBe(reason.text);
      });
    });

    describe('when user selects any non-trust action', () => {
      it('shows non-trust reasons', () => {
        const reasonLength = REASON_OPTIONS.length;
        let reasons;

        USER_ACTION_OPTIONS.forEach((userAction) => {
          if (userAction !== TRUST_ACTION && userAction !== NO_ACTION) {
            selectAction(userAction.value);

            reasons = findReasonOptions().findAll('option');
            expect(reasons).toHaveLength(reasonLength);
          }
        });
      });
    });

    describe('when user selects "Trust user"', () => {
      beforeEach(() => {
        selectAction(TRUST_ACTION.value);
      });

      it('only shows "Confirmed trusted user" reason', () => {
        const reasons = findReasonOptions().findAll('option');

        expect(reasons).toHaveLength(1);

        expect(reasons.at(0).text()).toBe(TRUST_REASON.text);
      });
    });
  });

  describe('when clicking the actions button', () => {
    beforeEach(() => {
      clickActionsButton();
    });

    it('shows the drawer', () => {
      expect(isDrawerOpen()).toBe(true);
    });

    describe.each`
      input       | errorFor    | messageShown
      ${null}     | ${'action'} | ${true}
      ${null}     | ${'reason'} | ${true}
      ${'close'}  | ${'action'} | ${false}
      ${'action'} | ${'action'} | ${false}
      ${'reason'} | ${'reason'} | ${false}
    `('when submitting an invalid form', ({ input, errorFor, messageShown }) => {
      describe(`when ${
        input ? `providing a value for the ${input} field` : 'not providing any values'
      }`, () => {
        beforeEach(() => {
          submitForm();

          if (input === 'close') {
            setCloseReport(params.close);
          } else if (input === 'action') {
            selectAction(params.user_action);
          } else if (input === 'reason') {
            selectReason(params.reason);
          }
        });

        it(`${messageShown ? 'shows' : 'hides'} ${errorFor} error message`, () => {
          if (messageShown) {
            expect(findErrorFor(errorFor).text()).toBe(ACTIONS_I18N.requiredFieldFeedback);
          } else {
            expect(findErrorFor(errorFor).exists()).toBe(false);
          }
        });
      });
    });

    describe('when submitting a valid form', () => {
      describe.each`
        response             | success  | responseStatus                       | responseData               | alertType        | alertMessage
        ${'successful'}      | ${true}  | ${HTTP_STATUS_OK}                    | ${{ message: 'success!' }} | ${SUCCESS_ALERT} | ${'success!'}
        ${'custom failure'}  | ${false} | ${HTTP_STATUS_UNPROCESSABLE_ENTITY}  | ${{ message: 'fail!' }}    | ${FAILED_ALERT}  | ${'fail!'}
        ${'generic failure'} | ${false} | ${HTTP_STATUS_INTERNAL_SERVER_ERROR} | ${{}}                      | ${FAILED_ALERT}  | ${ERROR_MESSAGE}
      `(
        'when the server responds with a $response response',
        ({ success, responseStatus, responseData, alertType, alertMessage }) => {
          beforeEach(async () => {
            jest.spyOn(axios, 'put');

            axiosMock.onPut(report.moderateUserPath).replyOnce(responseStatus, responseData);

            selectAction(params.user_action);
            setCloseReport(params.close);
            selectReason(params.reason);
            setComment(params.comment);

            await nextTick();

            submitForm();

            await waitForPromises();
          });

          it('does a put call with the right data', () => {
            expect(axios.put).toHaveBeenCalledWith(report.moderateUserPath, params);
          });

          it('closes the drawer', () => {
            expect(isDrawerOpen()).toBe(false);
          });

          it('emits the showAlert event', () => {
            expect(wrapper.emitted('showAlert')).toStrictEqual([[alertType, alertMessage]]);
          });

          it(`${success ? 'does' : 'does not'} emit the closeReport event`, () => {
            if (success) {
              expect(wrapper.emitted('closeReport')).toBeDefined();
            } else {
              expect(wrapper.emitted('closeReport')).toBeUndefined();
            }
          });
        },
      );
    });
  });
});
