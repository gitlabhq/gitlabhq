import { GlKeysetPagination } from '@gitlab/ui';
import { omit } from 'lodash';
import { shallowMount } from '@vue/test-utils';
import currentUserOrganizationsGraphQlResponse from 'test_fixtures/graphql/organizations/current_user_organizations.query.graphql.json';
import OrganizationsList from '~/organizations/shared/components/list/organizations_list.vue';
import OrganizationsListItem from '~/organizations/shared/components/list/organizations_list_item.vue';
import { pageInfoMultiplePages, pageInfoOnePage } from 'jest/organizations/mock_data';

describe('OrganizationsList', () => {
  let wrapper;

  const {
    data: {
      currentUser: { organizations },
    },
  } = currentUserOrganizationsGraphQlResponse;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMount(OrganizationsList, {
      propsData: {
        organizations,
        ...propsData,
      },
    });
  };

  const findAllOrganizationsListItem = () => wrapper.findAllComponents(OrganizationsListItem);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);

  describe('template', () => {
    it('renders a list item for each organization', () => {
      createComponent();

      expect(findAllOrganizationsListItem()).toHaveLength(organizations.nodes.length);
    });

    describe('when there is one page of organizations', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            organizations: {
              ...organizations,
              pageInfo: pageInfoOnePage,
            },
          },
        });
      });

      it('does not render pagination', () => {
        expect(findPagination().exists()).toBe(false);
      });
    });

    describe('when there are multiple pages of organizations', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            organizations: {
              ...organizations,
              pageInfo: pageInfoMultiplePages,
            },
          },
        });
      });

      it('renders pagination', () => {
        expect(findPagination().props()).toMatchObject(omit(pageInfoMultiplePages, '__typename'));
      });

      describe('when `GlKeysetPagination` emits `next` event', () => {
        const endCursor = 'mockEndCursor';

        beforeEach(() => {
          findPagination().vm.$emit('next', endCursor);
        });

        it('emits `next` event', () => {
          expect(wrapper.emitted('next')).toEqual([[endCursor]]);
        });
      });

      describe('when `GlKeysetPagination` emits `prev` event', () => {
        const startCursor = 'startEndCursor';

        beforeEach(() => {
          findPagination().vm.$emit('prev', startCursor);
        });

        it('emits `prev` event', () => {
          expect(wrapper.emitted('prev')).toEqual([[startCursor]]);
        });
      });
    });
  });
});
