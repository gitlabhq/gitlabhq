import { GlFormGroup, GlSprintf, GlModal } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { createWrapper } from '@vue/test-utils';
import { BV_HIDE_MODAL } from '~/lib/utils/constants';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as ProjectsApi from '~/api/projects_api';
import ImportProjectMembersModal from '~/invite_members/components/import_project_members_modal.vue';
import ProjectSelect from '~/invite_members/components/project_select.vue';
import axios from '~/lib/utils/axios_utils';
import {
  displaySuccessfulInvitationAlert,
  reloadOnInvitationSuccess,
} from '~/invite_members/utils/trigger_successful_invite_alert';

jest.mock('~/invite_members/utils/trigger_successful_invite_alert');

let wrapper;
let mock;

const projectId = '1';
const projectName = 'test name';
const projectToBeImported = { id: '2' };
const $toast = {
  show: jest.fn(),
};

const createComponent = ({ props = {} } = {}) => {
  wrapper = shallowMountExtended(ImportProjectMembersModal, {
    propsData: {
      projectId,
      projectName,
      ...props,
    },
    stubs: {
      GlModal: stubComponent(GlModal, {
        template:
          '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
      }),
      GlSprintf,
      GlFormGroup: stubComponent(GlFormGroup, {
        props: ['state', 'invalidFeedback'],
      }),
    },
    mocks: {
      $toast,
    },
  });
};

beforeEach(() => {
  gon.api_version = 'v4';
  mock = new MockAdapter(axios);
});

afterEach(() => {
  mock.restore();
});

describe('ImportProjectMembersModal', () => {
  const findGlModal = () => wrapper.findComponent(GlModal);
  const findIntroText = () => wrapper.findComponent({ ref: 'modalIntro' }).text();
  const clickImportButton = () => findGlModal().vm.$emit('primary', { preventDefault: jest.fn() });
  const closeModal = () => findGlModal().vm.$emit('hidden', { preventDefault: jest.fn() });
  const findFormGroup = () => wrapper.findByTestId('form-group');
  const formGroupInvalidFeedback = () => findFormGroup().props('invalidFeedback');
  const formGroupErrorState = () => findFormGroup().props('state');
  const findProjectSelect = () => wrapper.findComponent(ProjectSelect);

  describe('rendering the modal', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the modal with the correct title', () => {
      expect(findGlModal().props('title')).toBe('Import members from another project');
    });

    it('renders the Cancel button text correctly', () => {
      expect(findGlModal().props('actionCancel')).toMatchObject({
        text: 'Cancel',
      });
    });

    it('renders the Import button text correctly', () => {
      expect(findGlModal().props('actionPrimary')).toMatchObject({
        text: 'Import project members',
        attributes: {
          variant: 'confirm',
          disabled: true,
          loading: false,
        },
      });
    });

    it('renders the modal intro text correctly', () => {
      expect(findIntroText()).toBe("You're importing members to the test name project.");
    });

    it('sets isLoading to true when the Invite button is clicked', async () => {
      clickImportButton();

      await nextTick();

      expect(findGlModal().props('actionPrimary').attributes.loading).toBe(true);
    });
  });

  describe('submitting the import', () => {
    it('prevents closing', () => {
      const evt = { preventDefault: jest.fn() };
      createComponent();

      findGlModal().vm.$emit('primary', evt);

      expect(evt.preventDefault).toHaveBeenCalledTimes(1);
    });

    describe('when the import is successful with reloadPageOnSubmit', () => {
      beforeEach(() => {
        createComponent({
          props: { reloadPageOnSubmit: true },
        });

        findProjectSelect().vm.$emit('input', projectToBeImported);

        jest.spyOn(ProjectsApi, 'importProjectMembers').mockResolvedValue();

        clickImportButton();
      });

      it('calls displaySuccessfulInvitationAlert on mount', () => {
        expect(displaySuccessfulInvitationAlert).toHaveBeenCalled();
      });

      it('calls reloadOnInvitationSuccess', () => {
        expect(reloadOnInvitationSuccess).toHaveBeenCalled();
      });

      it('does not display the successful toastMessage', () => {
        expect($toast.show).not.toHaveBeenCalledWith(
          'Successfully imported',
          wrapper.vm.$options.toastOptions,
        );
      });
    });

    describe('when the import is successful', () => {
      beforeEach(() => {
        createComponent();

        findProjectSelect().vm.$emit('input', projectToBeImported);

        jest.spyOn(ProjectsApi, 'importProjectMembers').mockResolvedValue();

        clickImportButton();
      });

      it('calls Api importProjectMembers', () => {
        expect(ProjectsApi.importProjectMembers).toHaveBeenCalledWith(
          projectId,
          projectToBeImported.id,
        );
      });

      it('displays the successful toastMessage', () => {
        expect($toast.show).toHaveBeenCalledWith(
          'Successfully imported',
          wrapper.vm.$options.toastOptions,
        );
      });

      it('hides the modal', () => {
        const rootWrapper = createWrapper(wrapper.vm.$root);

        expect(rootWrapper.emitted(BV_HIDE_MODAL)).toHaveLength(1);
      });

      it('does not call displaySuccessfulInvitationAlert on mount', () => {
        expect(displaySuccessfulInvitationAlert).not.toHaveBeenCalled();
      });

      it('does not call reloadOnInvitationSuccess', () => {
        expect(reloadOnInvitationSuccess).not.toHaveBeenCalled();
      });

      it('sets isLoading to false after success', () => {
        expect(findGlModal().props('actionPrimary').attributes.loading).toBe(false);
      });
    });

    describe('when the import fails', () => {
      beforeEach(async () => {
        createComponent();

        findProjectSelect().vm.$emit('input', projectToBeImported);

        jest
          .spyOn(ProjectsApi, 'importProjectMembers')
          .mockRejectedValue({ response: { data: { success: false } } });

        clickImportButton();
        await waitForPromises();
      });

      it('displays the generic error message', () => {
        expect(formGroupInvalidFeedback()).toBe('Unable to import project members');
        expect(formGroupErrorState()).toBe(false);
      });

      it('sets isLoading to false after error', () => {
        expect(findGlModal().props('actionPrimary').attributes.loading).toBe(false);
      });

      it('clears the error when the modal is closed with an error', async () => {
        expect(formGroupInvalidFeedback()).toBe('Unable to import project members');
        expect(formGroupErrorState()).toBe(false);

        closeModal();

        await nextTick();

        expect(formGroupInvalidFeedback()).toBe('');
        expect(formGroupErrorState()).not.toBe(false);
      });
    });
  });
});
