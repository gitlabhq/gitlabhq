import { GlFormGroup, GlSprintf, GlModal, GlCollapse, GlIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { createWrapper } from '@vue/test-utils';
import { BV_HIDE_MODAL } from '~/lib/utils/constants';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import * as ProjectsApi from '~/api/projects_api';
import eventHub from '~/invite_members/event_hub';
import ImportProjectMembersModal from '~/invite_members/components/import_project_members_modal.vue';
import ProjectSelect from '~/invite_members/components/project_select.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_CREATED, HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';

import {
  displaySuccessfulInvitationAlert,
  reloadOnInvitationSuccess,
} from '~/invite_members/utils/trigger_successful_invite_alert';

import {
  EXPANDED_ERRORS,
  IMPORT_PROJECT_MEMBERS_MODAL_TRACKING_CATEGORY,
  IMPORT_PROJECT_MEMBERS_MODAL_TRACKING_LABEL,
} from '~/invite_members/constants';
import {
  IMPORT_PROJECT_MEMBERS_PATH,
  importProjectMembersApiResponse,
} from '../mock_data/api_responses';

jest.mock('~/invite_members/utils/trigger_successful_invite_alert');

let wrapper;
let mock;
let trackingSpy;

const projectId = '1';
const projectName = 'test name';
const projectToBeImported = { id: '2' };
const $toast = {
  show: jest.fn(),
};

const expectTracking = (action) =>
  expect(trackingSpy).toHaveBeenCalledWith(IMPORT_PROJECT_MEMBERS_MODAL_TRACKING_CATEGORY, action, {
    label: IMPORT_PROJECT_MEMBERS_MODAL_TRACKING_LABEL,
    category: IMPORT_PROJECT_MEMBERS_MODAL_TRACKING_CATEGORY,
    property: undefined,
  });

const triggerOpenModal = async () => {
  eventHub.$emit('openProjectMembersModal');
  await nextTick();
};

const createComponent = ({ props = {}, provide = {} } = {}) => {
  wrapper = shallowMountExtended(ImportProjectMembersModal, {
    provide: {
      ...provide,
    },
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

  trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
};

beforeEach(() => {
  gon.api_version = 'v4';
  mock = new MockAdapter(axios);
});

afterEach(() => {
  mock.restore();
  unmockTracking();
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
  const findMemberErrorAlert = () => wrapper.findByTestId('alert-member-error');
  const findMoreInviteErrorsButton = () => wrapper.findByTestId('accordion-button');
  const findAccordion = () => wrapper.findComponent(GlCollapse);
  const findErrorsIcon = () => wrapper.findComponent(GlIcon);
  const findSeatOveragesAlert = () =>
    wrapper.findByTestId('import-project-members-seat-overages-alert');
  const findMemberErrorMessage = (element) =>
    `@${Object.keys(importProjectMembersApiResponse.EXPANDED_IMPORT_ERRORS.message)[element]}: ${
      Object.values(importProjectMembersApiResponse.EXPANDED_IMPORT_ERRORS.message)[element]
    }`;

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

    it('tracks render', async () => {
      await triggerOpenModal();

      expectTracking('render');
    });

    it('tracks cancel', () => {
      findGlModal().vm.$emit('cancel');

      expectTracking('click_cancel');
    });

    it('tracks close', () => {
      findGlModal().vm.$emit('close');

      expectTracking('click_x');
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

      it('tracks successful import', () => {
        expectTracking('invite_successful');
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

      it('tracks successful import', () => {
        expectTracking('invite_successful');
      });
    });

    describe('when the import fails due to generic api error', () => {
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

    describe('when the api error includes an error message', () => {
      beforeEach(async () => {
        createComponent();

        findProjectSelect().vm.$emit('input', projectToBeImported);

        jest.spyOn(ProjectsApi, 'importProjectMembers').mockRejectedValue({
          response: { data: { success: false, message: 'Failure message' } },
        });

        clickImportButton();
        await waitForPromises();
      });

      it('displays the error message from the api', () => {
        expect(formGroupInvalidFeedback()).toBe('Failure message');
        expect(formGroupErrorState()).toBe(false);
      });
    });

    describe('when the import fails with member import errors', () => {
      const mockInvitationsApi = (code, data) => {
        mock.onPost(IMPORT_PROJECT_MEMBERS_PATH).reply(code, data);
      };

      beforeEach(() => {
        createComponent();
        findProjectSelect().vm.$emit('input', projectToBeImported);
      });

      it('displays the error alert', async () => {
        mockInvitationsApi(
          HTTP_STATUS_CREATED,
          importProjectMembersApiResponse.NO_COLLAPSE_IMPORT_ERRORS,
        );

        clickImportButton();
        await waitForPromises();

        expect(findMemberErrorAlert().props('title')).toContain(
          'The following 2 out of 2 members could not be added',
        );
        expect(findMemberErrorAlert().text()).toContain(findMemberErrorMessage(0));
        expect(findMemberErrorAlert().text()).toContain(findMemberErrorMessage(1));
      });

      it('displays collapse when there are more than 2 errors', async () => {
        mockInvitationsApi(
          HTTP_STATUS_CREATED,
          importProjectMembersApiResponse.EXPANDED_IMPORT_ERRORS,
        );

        clickImportButton();
        await waitForPromises();

        expect(findAccordion().exists()).toBe(true);
        expect(findMoreInviteErrorsButton().text()).toContain('Show more (2)');
      });

      it('toggles the collapse on click', async () => {
        mockInvitationsApi(
          HTTP_STATUS_CREATED,
          importProjectMembersApiResponse.EXPANDED_IMPORT_ERRORS,
        );

        clickImportButton();
        await waitForPromises();

        expect(findMoreInviteErrorsButton().text()).toContain('Show more (2)');
        expect(findErrorsIcon().attributes('class')).not.toContain('gl-rotate-180');
        expect(findAccordion().attributes('visible')).toBeUndefined();

        await findMoreInviteErrorsButton().vm.$emit('click');

        expect(findMoreInviteErrorsButton().text()).toContain(EXPANDED_ERRORS);
        expect(findErrorsIcon().attributes('class')).toContain('gl-rotate-180');
        expect(findAccordion().attributes('visible')).toBeDefined();

        await findMoreInviteErrorsButton().vm.$emit('click');

        expect(findMoreInviteErrorsButton().text()).toContain('Show more (2)');
      });

      it("doesn't display collapse when there are 2 or less errors", async () => {
        mockInvitationsApi(
          HTTP_STATUS_CREATED,
          importProjectMembersApiResponse.NO_COLLAPSE_IMPORT_ERRORS,
        );

        clickImportButton();
        await waitForPromises();

        expect(findAccordion().exists()).toBe(false);
        expect(findMoreInviteErrorsButton().exists()).toBe(false);
      });
    });

    describe('when the import fails due to a seat overage', () => {
      const mockInvitationsApi = (code, data) => {
        mock.onPost(IMPORT_PROJECT_MEMBERS_PATH).reply(code, data);
      };

      beforeEach(() => {
        createComponent({ provide: { addSeatsHref: 'add_seats_url' } });
        findProjectSelect().vm.$emit('input', projectToBeImported);
      });

      it('clears the error when the modal is closed', async () => {
        mockInvitationsApi(
          HTTP_STATUS_UNPROCESSABLE_ENTITY,
          importProjectMembersApiResponse.SEAT_OVERAGE_IMPORT_ERRORS,
        );

        clickImportButton();
        await waitForPromises();

        expect(formGroupInvalidFeedback()).toBe(
          'There are not enough available seats to invite this many users.',
        );
        expect(formGroupErrorState()).toBe(false);
        expect(findSeatOveragesAlert().exists()).toBe(true);

        closeModal();

        await nextTick();

        expect(formGroupInvalidFeedback()).toBe('');
        expect(formGroupErrorState()).not.toBe(false);
        expect(findSeatOveragesAlert().exists()).toBe(false);
      });
    });
  });
});
