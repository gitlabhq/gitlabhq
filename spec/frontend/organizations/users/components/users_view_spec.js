import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { GlLoadingIcon, GlKeysetPagination, GlCollapsibleListbox } from '@gitlab/ui';
import organizationUserUpdateResponse from 'test_fixtures/graphql/organizations/organization_user_update.mutation.graphql.json';
import organizationUserUpdateResponseWithErrors from 'test_fixtures/graphql/organizations/organization_user_update.mutation.graphql_with_errors.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UsersView from '~/organizations/users/components/users_view.vue';
import UsersTable from '~/vue_shared/components/users_table/users_table.vue';
import organizationUserUpdateMutation from '~/organizations/users/graphql/mutations/organization_user_update.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createAlert } from '~/alert';
import waitForPromises from 'helpers/wait_for_promises';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { pageInfoMultiplePages } from 'jest/organizations/mock_data';
import { MOCK_PATHS, MOCK_USERS_FORMATTED } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('UsersView', () => {
  let wrapper;
  let mockApollo;

  const successfulResponseHandler = jest.fn().mockResolvedValue(organizationUserUpdateResponse);
  const mockToastShow = jest.fn();

  const createComponent = ({ propsData = {}, handler = successfulResponseHandler } = {}) => {
    mockApollo = createMockApollo([[organizationUserUpdateMutation, handler]]);

    wrapper = mountExtended(UsersView, {
      propsData: {
        loading: false,
        users: MOCK_USERS_FORMATTED,
        pageInfo: pageInfoMultiplePages,
        ...propsData,
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

  const findGlLoading = () => wrapper.findComponent(GlLoadingIcon);
  const findUsersTable = () => wrapper.findComponent(UsersTable);
  const findGlKeysetPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const listboxSelectOwner = () => findListbox().vm.$emit('select', 'OWNER');

  afterEach(() => {
    mockApollo = null;
  });

  describe.each`
    description                            | loading  | usersData
    ${'when loading'}                      | ${true}  | ${[]}
    ${'when not loading and has users'}    | ${false} | ${MOCK_USERS_FORMATTED}
    ${'when not loading and has no users'} | ${false} | ${[]}
  `('$description', ({ loading, usersData }) => {
    beforeEach(() => {
      createComponent({ propsData: { loading, users: usersData } });
    });

    it(`does ${loading ? '' : 'not '}render loading icon`, () => {
      expect(findGlLoading().exists()).toBe(loading);
    });

    it(`does ${!loading ? '' : 'not '}render users table`, () => {
      expect(findUsersTable().exists()).toBe(!loading);
    });

    it(`does ${!loading ? '' : 'not '}render pagination`, () => {
      expect(findGlKeysetPagination().exists()).toBe(Boolean(!loading));
    });
  });

  describe('Pagination', () => {
    beforeEach(() => {
      createComponent();
    });

    it('@next event forwards up to the parent component', () => {
      findGlKeysetPagination().vm.$emit('next');

      expect(wrapper.emitted('next')).toHaveLength(1);
    });

    it('@prev event forwards up to the parent component', () => {
      findGlKeysetPagination().vm.$emit('prev');

      expect(wrapper.emitted('prev')).toHaveLength(1);
    });
  });

  describe('Organization role', () => {
    it('renders listbox with role options', () => {
      createComponent();

      expect(wrapper.findComponent(GlCollapsibleListbox).props()).toMatchObject({
        items: [
          {
            text: 'User',
            value: 'DEFAULT',
          },
          {
            text: 'Owner',
            value: 'OWNER',
          },
        ],
        selected: MOCK_USERS_FORMATTED[0].accessLevel.stringValue,
        disabled: false,
      });
    });

    it('does not render tooltip', () => {
      createComponent();

      const tooltipContainer = findListbox().element.parentNode;
      const tooltip = getBinding(tooltipContainer, 'gl-tooltip');

      expect(tooltip.value.disabled).toBe(true);
      expect(tooltipContainer.getAttribute('tabindex')).toBe(null);
    });

    describe('when user is last owner of organization', () => {
      const [firstUser] = MOCK_USERS_FORMATTED;

      beforeEach(() => {
        createComponent({
          propsData: {
            loading: false,
            users: [{ ...firstUser, isLastOwner: true }],
          },
        });
      });

      it('renders listbox as disabled', () => {
        expect(findListbox().props('disabled')).toBe(true);
      });

      it('renders tooltip and makes element focusable', () => {
        const tooltipContainer = findListbox().element.parentNode;
        const tooltip = getBinding(tooltipContainer, 'gl-tooltip');

        expect(tooltip.value).toEqual({
          title: 'Organizations must have at least one owner.',
          disabled: false,
        });
        expect(tooltipContainer.getAttribute('tabindex')).toBe('0');
      });
    });

    describe('when role is changed', () => {
      afterEach(async () => {
        // clean up any unresolved GraphQL mutations
        await waitForPromises();
      });

      it('calls GraphQL mutation with correct variables', () => {
        createComponent();
        listboxSelectOwner();

        expect(successfulResponseHandler).toHaveBeenCalledWith({
          input: {
            id: MOCK_USERS_FORMATTED[0].gid,
            accessLevel: 'OWNER',
          },
        });
      });

      it('shows dropdown as loading while waiting for GraphQL mutation', async () => {
        createComponent();
        listboxSelectOwner();

        await nextTick();

        expect(findListbox().props('loading')).toBe(true);
      });

      it('shows toast when GraphQL mutation is successful', async () => {
        createComponent();
        listboxSelectOwner();

        await waitForPromises();

        expect(mockToastShow).toHaveBeenCalledWith('Organization role was updated successfully.');
      });

      it('emits role-change event when GraphQL mutation is successful', async () => {
        createComponent();
        listboxSelectOwner();

        await waitForPromises();

        expect(wrapper.emitted('role-change')).toEqual([[]]);
      });

      it('calls createAlert when GraphQL mutation has validation error', async () => {
        const errorResponseHandler = jest
          .fn()
          .mockResolvedValue(organizationUserUpdateResponseWithErrors);
        createComponent({
          handler: errorResponseHandler,
        });

        listboxSelectOwner();

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'You cannot change the access of the last owner from the organization',
        });
      });

      it('calls createAlert when GraphQL mutation has network error', async () => {
        const error = new Error();
        const errorResponseHandler = jest.fn().mockRejectedValue(error);

        createComponent({
          handler: errorResponseHandler,
        });

        listboxSelectOwner();

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred updating the organization role. Please try again.',
          error,
          captureError: true,
        });
      });
    });
  });
});
