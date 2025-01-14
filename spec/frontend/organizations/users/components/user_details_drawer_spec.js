import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlCollapsibleListbox, GlDrawer } from '@gitlab/ui';
import organizationUserUpdateResponseWithErrors from 'test_fixtures/graphql/organizations/organization_user_update.mutation.graphql_with_errors.json';
import organizationUserUpdateResponse from 'test_fixtures/graphql/organizations/organization_user_update.mutation.graphql.json';
import organizationUserUpdateMutation from '~/organizations/users/graphql/mutations/organization_user_update.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { pageInfoMultiplePages } from 'jest/organizations/mock_data';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import UserDetailsDrawer from '~/organizations/users/components/user_details_drawer.vue';
import UserAvatar from '~/vue_shared/components/users_table/user_avatar.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import {
  ACCESS_LEVEL_DEFAULT_STRING,
  ACCESS_LEVEL_OWNER_STRING,
} from '~/organizations/shared/constants';
import { MOCK_PATHS, MOCK_USERS_FORMATTED } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('UserDetailsDrawer', () => {
  let wrapper;
  let mockApollo;

  const mockUser = MOCK_USERS_FORMATTED[0];

  const successfulResponseHandler = jest.fn().mockResolvedValue(organizationUserUpdateResponse);
  const mockToastShow = jest.fn();

  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findGlDrawer = () => wrapper.findComponent(GlDrawer);
  const findGlCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findUserAvatar = () => wrapper.findComponent(UserAvatar);
  const findFooter = () => wrapper.findByTestId('user-details-drawer-footer');
  const findSaveButton = () => wrapper.findByRole('button', { name: 'Save' });
  const findCancelButton = () => wrapper.findByRole('button', { name: 'Cancel' });

  const selectRole = (value) => findGlCollapsibleListbox().vm.$emit('select', value);

  const createComponent = ({
    mountFn = shallowMountExtended,
    props = {},
    handler = successfulResponseHandler,
  } = {}) => {
    mockApollo = createMockApollo([[organizationUserUpdateMutation, handler]]);

    wrapper = mountFn(UserDetailsDrawer, {
      propsData: {
        user: mockUser,
        pageInfo: pageInfoMultiplePages,
        ...props,
      },
      provide: {
        paths: MOCK_PATHS,
      },
      apolloProvider: mockApollo,
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  afterEach(() => {
    mockApollo = null;
  });

  describe('when there is no active user', () => {
    it('does not render drawer', () => {
      createComponent({ props: { user: null } });

      expect(findGlDrawer().exists()).toBe(false);
    });
  });

  describe('when there is an active user', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders open drawer', () => {
      expect(findGlDrawer().exists()).toBe(true);
      expect(findGlDrawer().props('open')).toBe(true);
    });

    it('renders drawer title', () => {
      expect(findGlDrawer().text()).toContain('Organization user details');
    });

    it('renders user avatar', () => {
      expect(findUserAvatar().props()).toMatchObject({
        user: mockUser,
        adminUserPath: MOCK_PATHS.adminUser,
      });
    });

    it('does not render footer and action buttons', () => {
      expect(findFooter().exists()).toBe(false);
      expect(findSaveButton().exists()).toBe(false);
      expect(findCancelButton().exists()).toBe(false);
    });

    it('renders role listbox label', () => {
      expect(findGlDrawer().text()).toContain('Organization role');
    });

    it('renders role listbox correct props', () => {
      expect(findGlCollapsibleListbox().props()).toMatchObject({
        items: UserDetailsDrawer.roleListboxItems,
        selected: mockUser.accessLevel.stringValue,
        disabled: false,
      });
    });

    it('does not render disabled listbox tooltip', () => {
      const tooltipContainer = findGlCollapsibleListbox().element.parentNode;
      const tooltip = getBinding(tooltipContainer, 'gl-tooltip');

      expect(tooltip.value.disabled).toBe(true);
      expect(tooltipContainer.getAttribute('tabindex')).toBe(null);
    });

    describe('when user is last owner of organization', () => {
      beforeEach(() => {
        createComponent({
          props: {
            loading: false,
            user: { ...mockUser, isLastOwner: true },
          },
        });
      });

      it('renders listbox as disabled', () => {
        expect(findGlCollapsibleListbox().props('disabled')).toBe(true);
      });

      it('renders tooltip and makes element focusable', () => {
        const tooltipContainer = findGlCollapsibleListbox().element.parentNode;
        const tooltip = getBinding(tooltipContainer, 'gl-tooltip');

        expect(tooltip.value).toEqual({
          title: 'Organizations must have at least one owner.',
          disabled: false,
        });
        expect(tooltipContainer.getAttribute('tabindex')).toBe('0');
      });
    });

    describe('when selecting new role', () => {
      const unselectedRole =
        mockUser.accessLevel.stringValue === ACCESS_LEVEL_OWNER_STRING
          ? ACCESS_LEVEL_DEFAULT_STRING
          : ACCESS_LEVEL_OWNER_STRING;

      beforeEach(() => {
        createComponent({ mountFn: mountExtended });

        selectRole(unselectedRole);
      });

      it('renders footer and action buttons', () => {
        expect(findFooter().exists()).toBe(true);
        expect(findSaveButton().exists()).toBe(true);
        expect(findCancelButton().exists()).toBe(true);
      });

      it('does not render remove self as owner warning', () => {
        expect(findGlAlert().exists()).toBe(false);
      });

      describe('when active user is the current user', () => {
        beforeEach(() => {
          window.gon.current_user_id = mockUser.id;
        });

        describe('when removing self as owner', () => {
          beforeEach(() => {
            createComponent({
              props: {
                user: {
                  ...mockUser,
                  accessLevel: { ...mockUser.accessLevel, stringValue: ACCESS_LEVEL_OWNER_STRING },
                },
              },
            });

            selectRole(ACCESS_LEVEL_DEFAULT_STRING);
          });

          it('renders remove self as owner warning', () => {
            expect(findGlAlert().text()).toBe(
              'If you proceed with this change you will lose your owner permissions for this organization, including access to this page.',
            );
          });
        });
      });

      describe('when save button is clicked', () => {
        beforeEach(async () => {
          await findSaveButton().trigger('click');
          await nextTick();
        });

        it('calls GraphQL mutation with correct variables', () => {
          expect(successfulResponseHandler).toHaveBeenCalledWith({
            input: {
              id: mockUser.gid,
              accessLevel: unselectedRole,
            },
          });
        });

        it('sets listbox to loading', () => {
          expect(findGlCollapsibleListbox().props('loading')).toBe(true);
        });

        it('emits loading start event', () => {
          expect(wrapper.emitted('loading')[0]).toEqual([true]);
        });

        describe('when role update is successful', () => {
          beforeEach(async () => {
            await waitForPromises();
          });

          it('shows toast when GraphQL mutation is successful', () => {
            expect(mockToastShow).toHaveBeenCalledWith(
              'Organization role was updated successfully.',
            );
          });

          it('emits role-change event', () => {
            expect(wrapper.emitted('role-change')).toHaveLength(1);
          });

          it('emits loading end event', () => {
            expect(wrapper.emitted('loading')[1]).toEqual([false]);
          });
        });

        describe('when role update has a validation error', () => {
          beforeEach(async () => {
            const errorResponseHandler = jest
              .fn()
              .mockResolvedValue(organizationUserUpdateResponseWithErrors);

            createComponent({
              mountFn: mountExtended,
              handler: errorResponseHandler,
            });

            selectRole(unselectedRole);
            await nextTick();

            await findSaveButton().trigger('click');
            await waitForPromises();
          });

          it('creates an alert', () => {
            expect(createAlert).toHaveBeenCalledWith({
              message: 'You cannot change the access of the last owner from the organization',
            });
          });
        });

        describe('when role update has a network error', () => {
          const error = new Error();

          beforeEach(async () => {
            const errorResponseHandler = jest.fn().mockRejectedValue(error);

            createComponent({
              mountFn: mountExtended,
              handler: errorResponseHandler,
            });

            selectRole(unselectedRole);
            await nextTick();

            await findSaveButton().trigger('click');
            await waitForPromises();
          });

          it('creates an alert', () => {
            expect(createAlert).toHaveBeenCalledWith({
              message: 'An error occurred updating the organization role. Please try again.',
              error,
              captureError: true,
            });
          });
        });
      });

      describe('when cancel button is clicked', () => {
        it('resets listbox to the initial user role', async () => {
          await findCancelButton().trigger('click');

          expect(findGlCollapsibleListbox().props('selected')).toBe(
            mockUser.accessLevel.stringValue,
          );
        });
      });
    });

    describe('when drawer is closed', () => {
      it('emits close event', () => {
        findGlDrawer().vm.$emit('close');

        expect(wrapper.emitted('close')).toHaveLength(1);
      });
    });
  });
});
