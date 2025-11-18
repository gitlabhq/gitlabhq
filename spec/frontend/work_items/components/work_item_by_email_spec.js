import {
  GlModal,
  GlSprintf,
  GlFormInputGroup,
  GlButton,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemByEmail from '~/work_items/components/work_item_by_email.vue';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import namespaceRegenerateNewWorkItemEmailAddressMutation from '~/work_items/graphql/namespace_regenerate_new_work_item_email_address.mutation.graphql';

Vue.use(VueApollo);

const initialEmail = 'incoming+project-123-token-issue@example.com';

const mockToastShow = jest.fn();

describe('WorkItemByEmail', () => {
  let wrapper;
  let mockApollo;
  let glModalDirective;
  let mutationHandler;

  function createComponent(injectedProperties = {}) {
    glModalDirective = jest.fn();

    mockApollo = createMockApollo([
      [namespaceRegenerateNewWorkItemEmailAddressMutation, mutationHandler],
    ]);

    wrapper = extendedWrapper(
      shallowMount(WorkItemByEmail, {
        apolloProvider: mockApollo,
        stubs: {
          GlModal,
          GlSprintf,
          GlFormInputGroup,
          GlButton,
          ModalCopyButton,
          GlDisclosureDropdownItem,
        },
        directives: {
          glModal: {
            bind(_, { value }) {
              glModalDirective(value);
            },
          },
        },
        mocks: {
          $toast: {
            show: mockToastShow,
          },
        },
        provide: {
          newWorkItemEmailAddress: initialEmail,
          emailsHelpPagePath: '/help/development/emails.md#email-namespace',
          quickActionsHelpPath: '/help/user/project/quick_actions.md',
          markdownHelpPath: '/help/user/markdown.md',
          fullPath: 'gitlab-org/gitlab',
          ...injectedProperties,
        },
      }),
    );
  }

  beforeEach(() => {
    mutationHandler = jest.fn();
  });

  const findDisclosureDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findFormInputGroup = () => wrapper.findComponent(GlFormInputGroup);
  const findMailtoButton = () =>
    wrapper
      .findAllComponents(GlButton)
      .wrappers.find(
        (btn) => btn.attributes('href') && btn.attributes('href').startsWith('mailto:'),
      );

  const clickResetEmail = async () => {
    wrapper.findByTestId('reset_email_token_link').vm.$emit('click');

    await waitForPromises();
  };

  describe('modal button', () => {
    it('renders a link with "Email a new work item to this project"', () => {
      createComponent();
      expect(findDisclosureDropdownItem().text()).toBe('Email work item to this project');
    });

    it('opens the modal when the user clicks the button', () => {
      createComponent();

      findDisclosureDropdownItem().vm.$emit('click');

      expect(glModalDirective).toHaveBeenCalled();
    });
  });

  describe('modal', () => {
    it('renders a read-only email input field', () => {
      createComponent();

      expect(findFormInputGroup().props('value')).toBe(
        'incoming+project-123-token-issue@example.com',
      );
    });

    it('renders a mailto button', () => {
      createComponent();

      expect(findMailtoButton().attributes('href')).toBe(
        `mailto:${initialEmail}?subject=Enter the work item title&body=Enter the work item description`,
      );
    });

    describe('reset email', () => {
      it('should send request to reset email token', async () => {
        createComponent();

        await clickResetEmail();

        expect(mutationHandler).toHaveBeenCalledWith({
          fullPath: 'gitlab-org/gitlab',
        });
      });

      it('should update the email when the request succeeds', async () => {
        const newEmail = 'incoming+project-123-newtoken-issue@example.com';
        mutationHandler.mockResolvedValue({
          data: {
            namespacesRegenerateNewWorkItemEmailAddress: {
              errors: [],
              namespace: {
                id: '123',
                linkPaths: {
                  newWorkItemEmailAddress: newEmail,
                },
              },
            },
          },
        });

        createComponent();
        await clickResetEmail();
        expect(findFormInputGroup().props('value')).toBe(newEmail);
      });

      it('should show a toast message when the request fails', async () => {
        mutationHandler.mockResolvedValue({
          data: {
            namespacesRegenerateNewWorkItemEmailAddress: {
              errors: ['Failed to regenerate token'],
              namespace: null,
            },
          },
        });

        createComponent();

        await clickResetEmail();

        expect(mockToastShow).toHaveBeenCalledWith(
          'There was an error when resetting email token.',
        );
        expect(findFormInputGroup().props('value')).toBe(initialEmail);
      });
    });
  });
});
