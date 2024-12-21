import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NamespaceForm from '~/token_access/components/namespace_form.vue';
import addNamespaceMutation from '~/token_access/graphql/mutations/inbound_add_group_or_project_ci_job_token_scope.mutation.graphql';
import editNamespaceMutation from '~/token_access/graphql/mutations/edit_namespace_job_token_scope.mutation.graphql';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import PoliciesSelector from '~/token_access/components/policies_selector.vue';
import { getSaveNamespaceHandler } from './mock_data';

Vue.use(VueApollo);

describe('Namespace form component', () => {
  let wrapper;

  const defaultAddMutationHandler = getSaveNamespaceHandler();
  const defaultEditMutationHandler = getSaveNamespaceHandler();

  const createWrapper = ({
    namespace,
    addMutationHandler = defaultAddMutationHandler,
    editMutationHandler = defaultEditMutationHandler,
    addPoliciesToCiJobToken = true,
  } = {}) => {
    wrapper = shallowMountExtended(NamespaceForm, {
      apolloProvider: createMockApollo([
        [addNamespaceMutation, addMutationHandler],
        [editNamespaceMutation, editMutationHandler],
      ]),
      propsData: { namespace },
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
  const findSubmitButton = () => wrapper.findByTestId('submit-button');
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

    describe('Submit button', () => {
      it('shows button', () => {
        expect(findSubmitButton().text()).toBe('Add');
        expect(findSubmitButton().props()).toMatchObject({
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
        expect(findSubmitButton().props('disabled')).toBe(false);
      });

      describe('when the save button is clicked', () => {
        beforeEach(() => {
          findSubmitButton().vm.$emit('click');
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

        it('disables submit button', () => {
          expect(findSubmitButton().props('loading')).toBe(true);
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

          it('enables submit button', () => {
            expect(findSubmitButton().props('loading')).toBe(false);
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
    ${'when the mutation response contains an error'} | ${getSaveNamespaceHandler('some error')}
    ${'when the mutation throws an error'}            | ${jest.fn().mockRejectedValue(new Error('some error'))}
  `('$phrase', ({ addMutationHandler }) => {
    beforeEach(() => {
      createWrapper({ addMutationHandler });
      findSubmitButton().vm.$emit('click');

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

    it('enables submit button', () => {
      expect(findSubmitButton().props('loading')).toBe(false);
    });

    it('enables Cancel button', () => {
      expect(findCancelButton().props('disabled')).toBe(false);
    });

    describe.each`
      phrase                                   | actionFn
      ${'when the namespace input is changed'} | ${() => findFormInput().vm.$emit('input', 'gitlab2')}
      ${'when the submit button is clicked'}   | ${() => findSubmitButton().vm.$emit('click')}
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
        findSubmitButton().vm.$emit('click');

        expect(defaultAddMutationHandler).toHaveBeenCalledWith({
          projectPath: 'full/path',
          targetPath: 'gitlab',
        });
      });
    });
  });

  describe('editing a namespace', () => {
    beforeEach(() =>
      createWrapper({
        namespace: {
          fullPath: 'namespace/path',
          defaultPermissions: false,
          jobTokenPolicies: ['READ_JOBS'],
        },
      }),
    );

    describe('path input', () => {
      it('disables the input', () => {
        expect(findFormInput().props('disabled')).toBe(true);
      });

      it('shows the namespace full path', () => {
        expect(findFormInput().attributes('value')).toBe('namespace/path');
      });
    });

    it('passes expected values to the policies selector', () => {
      expect(findPoliciesSelector().props()).toMatchObject({
        isDefaultPermissionsSelected: false,
        jobTokenPolicies: ['READ_JOBS'],
      });
    });

    it('shows "Save" for the submit button text', () => {
      expect(findSubmitButton().text()).toBe('Save');
    });

    it('calls the edit mutation when the submit button is clicked', () => {
      findSubmitButton().vm.$emit('click');

      expect(defaultEditMutationHandler).toHaveBeenCalledTimes(1);
    });
  });
});
