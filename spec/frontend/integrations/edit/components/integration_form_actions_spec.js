import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ConfirmationModal from '~/integrations/edit/components/confirmation_modal.vue';
import ResetConfirmationModal from '~/integrations/edit/components/reset_confirmation_modal.vue';
import IntegrationFormActions from '~/integrations/edit/components/integration_form_actions.vue';

import { integrationLevels } from '~/integrations/constants';
import { createStore } from '~/integrations/edit/store';
import { mockIntegrationProps } from '../mock_data';

describe('IntegrationFormActions', () => {
  let wrapper;

  const createComponent = ({ customStateProps = {} } = {}) => {
    const store = createStore({
      customState: { ...mockIntegrationProps, ...customStateProps },
    });
    jest.spyOn(store, 'dispatch');

    wrapper = shallowMountExtended(IntegrationFormActions, {
      store,
      propsData: {
        hasSections: false,
      },
    });
  };

  const findConfirmationModal = () => wrapper.findComponent(ConfirmationModal);
  const findResetConfirmationModal = () => wrapper.findComponent(ResetConfirmationModal);
  const findResetButton = () => wrapper.findByTestId('reset-button');
  const findSaveButton = () => wrapper.findByTestId('save-changes-button');
  const findTestButton = () => wrapper.findByTestId('test-button');
  const findCancelButton = () => wrapper.findByTestId('cancel-button');

  describe('ConfirmationModal', () => {
    it.each`
      desc            | integrationLevel              | shouldRender
      ${'Should'}     | ${integrationLevels.INSTANCE} | ${true}
      ${'Should'}     | ${integrationLevels.GROUP}    | ${true}
      ${'Should not'} | ${integrationLevels.PROJECT}  | ${false}
    `(
      '$desc render the ConfirmationModal when integrationLevel is "$integrationLevel"',
      ({ integrationLevel, shouldRender }) => {
        createComponent({
          customStateProps: {
            integrationLevel,
          },
        });
        expect(findConfirmationModal().exists()).toBe(shouldRender);
      },
    );
  });

  describe('ResetConfirmationModal', () => {
    it.each`
      desc            | integrationLevel              | resetPath      | shouldRender
      ${'Should not'} | ${integrationLevels.INSTANCE} | ${''}          | ${false}
      ${'Should not'} | ${integrationLevels.GROUP}    | ${''}          | ${false}
      ${'Should not'} | ${integrationLevels.PROJECT}  | ${''}          | ${false}
      ${'Should'}     | ${integrationLevels.INSTANCE} | ${'resetPath'} | ${true}
      ${'Should'}     | ${integrationLevels.GROUP}    | ${'resetPath'} | ${true}
      ${'Should not'} | ${integrationLevels.PROJECT}  | ${'resetPath'} | ${false}
    `(
      '$desc render the ResetConfirmationModal modal when integrationLevel="$integrationLevel" and resetPath="$resetPath"',
      ({ integrationLevel, resetPath, shouldRender }) => {
        createComponent({
          customStateProps: {
            integrationLevel,
            resetPath,
          },
        });
        expect(findResetConfirmationModal().exists()).toBe(shouldRender);
      },
    );
  });

  describe('Buttons rendering', () => {
    it.each`
      integrationLevel              | canTest  | resetPath      | manualActivation | saveBtn | testBtn  | cancelBtn | resetBtn
      ${integrationLevels.PROJECT}  | ${true}  | ${'resetPath'} | ${true}          | ${true} | ${true}  | ${true}   | ${false}
      ${integrationLevels.PROJECT}  | ${false} | ${'resetPath'} | ${true}          | ${true} | ${false} | ${true}   | ${false}
      ${integrationLevels.PROJECT}  | ${true}  | ${''}          | ${true}          | ${true} | ${true}  | ${true}   | ${false}
      ${integrationLevels.GROUP}    | ${true}  | ${'resetPath'} | ${true}          | ${true} | ${true}  | ${true}   | ${true}
      ${integrationLevels.GROUP}    | ${true}  | ${'resetPath'} | ${false}         | ${true} | ${true}  | ${true}   | ${false}
      ${integrationLevels.GROUP}    | ${false} | ${'resetPath'} | ${true}          | ${true} | ${false} | ${true}   | ${true}
      ${integrationLevels.GROUP}    | ${true}  | ${''}          | ${true}          | ${true} | ${true}  | ${true}   | ${false}
      ${integrationLevels.INSTANCE} | ${true}  | ${'resetPath'} | ${true}          | ${true} | ${true}  | ${true}   | ${true}
      ${integrationLevels.INSTANCE} | ${true}  | ${'resetPath'} | ${false}         | ${true} | ${true}  | ${true}   | ${false}
      ${integrationLevels.INSTANCE} | ${false} | ${'resetPath'} | ${true}          | ${true} | ${false} | ${true}   | ${true}
      ${integrationLevels.INSTANCE} | ${true}  | ${''}          | ${true}          | ${true} | ${true}  | ${true}   | ${false}
    `(
      'on $integrationLevel when canTest="$canTest", resetPath="$resetPath" and manualActivation="$manualActivation"',
      ({
        integrationLevel,
        canTest,
        resetPath,
        manualActivation,
        saveBtn,
        testBtn,
        cancelBtn,
        resetBtn,
      }) => {
        createComponent({
          customStateProps: {
            integrationLevel,
            canTest,
            resetPath,
            manualActivation,
          },
        });

        expect(findSaveButton().exists()).toBe(saveBtn);
        expect(findTestButton().exists()).toBe(testBtn);
        expect(findCancelButton().exists()).toBe(cancelBtn);
        expect(findResetButton().exists()).toBe(resetBtn);
      },
    );
  });

  describe('interactions', () => {
    describe('Save button clicked', () => {
      const createAndSave = (integrationLevel, withModal = false) => {
        createComponent({
          customStateProps: {
            integrationLevel,
            canTest: true,
            resetPath: 'resetPath',
          },
        });

        findSaveButton().vm.$emit('click', new Event('click'));
        if (withModal) {
          findConfirmationModal().vm.$emit('submit');
        }
        wrapper.setProps({
          isSaving: true,
        });
      };
      const sharedFormStateTest = async (integrationLevel, withModal = false) => {
        createAndSave(integrationLevel, withModal);

        await nextTick();

        const saveBtnWrapper = findSaveButton();
        const testBtnWrapper = findTestButton();
        const cancelBtnWrapper = findCancelButton();

        expect(saveBtnWrapper.props('loading')).toBe(true);
        expect(saveBtnWrapper.props('disabled')).toBe(true);

        expect(testBtnWrapper.props('loading')).toBe(false);
        expect(testBtnWrapper.props('disabled')).toBe(true);

        expect(cancelBtnWrapper.props('loading')).toBe(false);
        expect(cancelBtnWrapper.props('disabled')).toBe(true);
      };

      describe('on "project" level', () => {
        const integrationLevel = integrationLevels.PROJECT;
        it('emits the "save" event right away', async () => {
          createAndSave(integrationLevel);
          await nextTick();

          expect(wrapper.emitted('save')).toHaveLength(1);
        });

        it('toggles the state of other buttons', async () => {
          await sharedFormStateTest(integrationLevel);

          const resetBtnWrapper = findResetButton();
          expect(resetBtnWrapper.exists()).toBe(false);
        });
      });

      describe.each([integrationLevels.INSTANCE, integrationLevels.GROUP])(
        'on "%s" level',
        (integrationLevel) => {
          it('emits the "save" event only after the confirmation', () => {
            createComponent({
              customStateProps: {
                integrationLevel,
              },
            });

            findSaveButton().vm.$emit('click', new Event('click'));
            expect(wrapper.emitted('save')).toBeUndefined();

            findConfirmationModal().vm.$emit('submit');
            expect(wrapper.emitted('save')).toHaveLength(1);
          });

          it('toggles the state of other buttons', async () => {
            await sharedFormStateTest(integrationLevel, true);

            const resetBtnWrapper = findResetButton();
            expect(resetBtnWrapper.props('loading')).toBe(false);
            expect(resetBtnWrapper.props('disabled')).toBe(true);
          });
        },
      );
    });

    describe('Reset button clicked', () => {
      describe.each([integrationLevels.INSTANCE, integrationLevels.GROUP])(
        'on "%s" level',
        (integrationLevel) => {
          it('emits the "reset" event only after the confirmation', () => {
            createComponent({
              customStateProps: {
                integrationLevel,
                resetPath: 'resetPath',
              },
            });

            findResetButton().vm.$emit('click', new Event('click'));
            expect(wrapper.emitted('reset')).toBeUndefined();

            findResetConfirmationModal().vm.$emit('reset');
            expect(wrapper.emitted('reset')).toHaveLength(1);
          });
        },
      );
    });

    describe('Test button clicked', () => {
      it('emits the "test" event when clicked', () => {
        createComponent({
          customStateProps: {
            integrationLevel: integrationLevels.PROJECT,
            canTest: true,
          },
        });

        findTestButton().vm.$emit('click', new Event('click'));
        expect(wrapper.emitted('test')).toHaveLength(1);
      });
    });
  });
});
