import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NamespaceForm from '~/token_access/components/namespace_form.vue';
import addNamespaceMutation from '~/token_access/graphql/mutations/inbound_add_group_or_project_ci_job_token_scope.mutation.graphql';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import PoliciesSelector from '~/token_access/components/policies_selector.vue';
import { getAddNamespaceHandler } from './mock_data';

Vue.use(VueApollo);

describe('Namespace form component', () => {
  let wrapper;

  const defaultAddMutationHandler = getAddNamespaceHandler();

  const createWrapper = ({
    addMutationHandler = defaultAddMutationHandler,
    addPoliciesToCiJobToken = true,
  } = {}) => {
    wrapper = shallowMountExtended(NamespaceForm, {
      apolloProvider: createMockApollo([[addNamespaceMutation, addMutationHandler]]),
      provide: { fullPath: 'full/path', glFeatures: { addPoliciesToCiJobToken } },
      stubs: {
        GlFormInput: stubComponent(GlFormInput, {
          props: ['autofocus', 'disabled', 'state', 'placeholder'],
        }),
      },
    });
  };

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findFormInput = () => wrapper.findComponent(GlFormInput);
  const findAddButton = () => wrapper.findByTestId('add-button');
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findPoliciesSelector = () => wrapper.findComponent(PoliciesSelector);

  describe('on page load', () => {
    beforeEach(() => createWrapper());

    describe('namespace text input', () => {
      it('shows form group', () => {
        expect(findFormGroup().attributes('label')).toBe('Group or project');
      });

      it('shows textbox', () => {
        expect(findFormInput().props()).toMatchObject({
          autofocus: '',
          placeholder: 'full/path',
        });
      });

      it('shows description', () => {
        expect(findFormGroup().props('labelDescription')).toBe(
          'Paste a group or project path to authorize access into this project.',
        );
      });
    });

    describe('policies selector', () => {
      it('shows policies selector', () => {
        expect(findPoliciesSelector().props()).toMatchObject({
          isDefaultPermissionsSelected: true,
          jobTokenPolicies: [],
          disabled: false,
        });
      });

      it('updates defaultPermissions when policies selector emits an update', async () => {
        findPoliciesSelector().vm.$emit('update:isDefaultPermissionsSelected', false);
        await nextTick();

        expect(findPoliciesSelector().props('isDefaultPermissionsSelected')).toBe(false);
      });

      it('updates jobTokenPolicies when policies selector emits an update', async () => {
        findPoliciesSelector().vm.$emit('update:jobTokenPolicies', ['ADMIN_JOB']);
        await nextTick();

        expect(findPoliciesSelector().props('jobTokenPolicies')).toEqual(['ADMIN_JOB']);
      });
    });

    describe('Add button', () => {
      it('shows button', () => {
        expect(findAddButton().text()).toBe('Add');
        expect(findAddButton().props()).toMatchObject({
          variant: 'confirm',
          disabled: true,
          loading: false,
        });
      });
    });

    describe('Cancel button', () => {
      it('shows button', () => {
        expect(findCancelButton().text()).toBe('Cancel');
        expect(findCancelButton().props('disabled')).toBe(false);
      });

      it('emits close event when clicked', () => {
        findCancelButton().vm.$emit('click');

        expect(wrapper.emitted('close')).toHaveLength(1);
      });
    });

    describe('when the namespace input has a value', () => {
      beforeEach(() => {
        findFormInput().vm.$emit('input', 'gitlab');
      });

      it('enables Save button', () => {
        expect(findAddButton().props('disabled')).toBe(false);
      });

      describe('when the save button is clicked', () => {
        beforeEach(() => {
          findAddButton().vm.$emit('click');
        });

        it('runs save mutation', () => {
          expect(defaultAddMutationHandler).toHaveBeenCalledTimes(1);
          expect(defaultAddMutationHandler).toHaveBeenCalledWith({
            projectPath: 'full/path',
            targetPath: 'gitlab',
            defaultPermissions: true,
            jobTokenPolicies: [],
          });
        });

        it('disables form input', () => {
          expect(findFormInput().props('disabled')).toBe(true);
        });

        it('disables policies selector', () => {
          expect(findPoliciesSelector().props('disabled')).toBe(true);
        });

        it('disables Add button', () => {
          expect(findAddButton().props('loading')).toBe(true);
        });

        it('disables Cancel button', () => {
          expect(findCancelButton().props('disabled')).toBe(true);
        });

        describe('when save is done', () => {
          beforeEach(() => waitForPromises());

          it('emits saved and close event', () => {
            expect(wrapper.emitted('saved')).toHaveLength(1);
            expect(wrapper.emitted('close')).toHaveLength(1);
          });

          it('enables form input', () => {
            expect(findFormInput().props('disabled')).toBe(false);
          });

          it('enables policies selector', () => {
            expect(findPoliciesSelector().props('disabled')).toBe(false);
          });

          it('enables Add button', () => {
            expect(findAddButton().props('loading')).toBe(false);
          });

          it('enables Cancel button', () => {
            expect(findCancelButton().props('disabled')).toBe(false);
          });
        });
      });
    });
  });

  describe.each`
    phrase                                            | addMutationHandler
    ${'when the mutation response contains an error'} | ${getAddNamespaceHandler('some error')}
    ${'when the mutation throws an error'}            | ${jest.fn().mockRejectedValue(new Error('some error'))}
  `('$phrase', ({ addMutationHandler }) => {
    beforeEach(() => {
      createWrapper({ addMutationHandler });
      findAddButton().vm.$emit('click');

      return waitForPromises();
    });

    it('shows error message', () => {
      expect(findFormGroup().attributes('invalid-feedback')).toBe('some error');
    });

    it('show form input error state', () => {
      expect(findFormInput().props('state')).toBe(false);
    });

    it('enables form input', () => {
      expect(findFormInput().props('disabled')).toBe(false);
    });

    it('enables Add button', () => {
      expect(findAddButton().props('loading')).toBe(false);
    });

    it('enables Cancel button', () => {
      expect(findCancelButton().props('disabled')).toBe(false);
    });

    describe.each`
      phrase                                   | actionFn
      ${'when the namespace input is changed'} | ${() => findFormInput().vm.$emit('input', 'gitlab2')}
      ${'when the Add button is clicked'}      | ${() => findAddButton().vm.$emit('click')}
    `('$phrase', ({ actionFn }) => {
      beforeEach(() => {
        actionFn();
        return nextTick();
      });

      it('clears error message', () => {
        expect(findFormGroup().attributes('invalid-feedback')).toBe('');
      });

      it('clears form input error state', () => {
        expect(findFormInput().props('state')).toBe(true);
      });
    });
  });

  describe('when the addPoliciesToCiJobToken feature flag is disabled', () => {
    beforeEach(() => createWrapper({ addPoliciesToCiJobToken: false }));

    it('does not show permissions selector', () => {
      expect(findPoliciesSelector().exists()).toBe(false);
    });

    describe('when namespace is saved', () => {
      it('calls mutation without defaultPermissions or jobTokenPolicies', () => {
        findFormInput().vm.$emit('input', 'gitlab');
        findAddButton().vm.$emit('click');

        expect(defaultAddMutationHandler).toHaveBeenCalledWith({
          projectPath: 'full/path',
          targetPath: 'gitlab',
        });
      });
    });
  });
});
