import Vue from 'vue';
import VueRouter from 'vue-router';
import { GlAvatar, GlBadge, GlButton, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createRouter } from '~/ci/catalog/router/index';
import CiResourcesListItem from '~/ci/catalog/components/list/ci_resources_list_item.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { CI_RESOURCE_DETAILS_PAGE_NAME } from '~/ci/catalog/router/constants';
import { catalogSinglePageResponse } from '../../mock';

Vue.use(VueRouter);

let router;
let routerPush;

describe('CiResourcesListItem', () => {
  let wrapper;

  const resource = catalogSinglePageResponse.data.ciCatalogResources.nodes[0];
  const release = {
    author: { name: 'author', webUrl: '/user/1' },
    releasedAt: Date.now(),
    tagName: '1.0.0',
  };
  const defaultProps = {
    resource,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(CiResourcesListItem, {
      router,
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlSprintf,
        RouterLink: true,
        RouterView: true,
      },
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findResourceName = () => wrapper.findComponent(GlButton);
  const findResourceDescription = () => wrapper.findByText(defaultProps.resource.description);
  const findUserLink = () => wrapper.findByTestId('user-link');
  const findTimeAgoMessage = () => wrapper.findComponent(GlSprintf);
  const findFavorites = () => wrapper.findByTestId('stats-favorites');
  const findForks = () => wrapper.findByTestId('stats-forks');

  beforeEach(() => {
    router = createRouter();
    routerPush = jest.spyOn(router, 'push').mockImplementation(() => {});
  });

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the resource avatar and passes the right props', () => {
      const { icon, id, name } = defaultProps.resource;

      expect(findAvatar().exists()).toBe(true);
      expect(findAvatar().props()).toMatchObject({
        entityId: getIdFromGraphQLId(id),
        entityName: name,
        src: icon,
      });
    });

    it('renders the resource name button', () => {
      expect(findResourceName().exists()).toBe(true);
    });

    it('renders the resource version badge', () => {
      expect(findBadge().exists()).toBe(true);
    });

    it('renders the resource description', () => {
      expect(findResourceDescription().exists()).toBe(true);
    });

    describe('release time', () => {
      describe('when there is no release data', () => {
        beforeEach(() => {
          createComponent({ props: { resource: { ...resource, latestVersion: null } } });
        });

        it('does not render the release', () => {
          expect(findTimeAgoMessage().exists()).toBe(false);
        });

        it('renders the generic `unreleased` badge', () => {
          expect(findBadge().exists()).toBe(true);
          expect(findBadge().text()).toBe('Unreleased');
        });
      });

      describe('when there is release data', () => {
        beforeEach(() => {
          createComponent({ props: { resource: { ...resource, latestVersion: { ...release } } } });
        });

        it('renders the user link', () => {
          expect(findUserLink().exists()).toBe(true);
          expect(findUserLink().attributes('href')).toBe(release.author.webUrl);
        });

        it('renders the time since the resource was released', () => {
          expect(findTimeAgoMessage().exists()).toBe(true);
        });

        it('renders the version badge', () => {
          expect(findBadge().exists()).toBe(true);
          expect(findBadge().text()).toBe(release.tagName);
        });
      });
    });
  });

  describe('when clicking on an item title', () => {
    beforeEach(async () => {
      createComponent();

      await findResourceName().vm.$emit('click');
    });

    it('navigates to the details page', () => {
      expect(routerPush).toHaveBeenCalledWith({
        name: CI_RESOURCE_DETAILS_PAGE_NAME,
        params: {
          id: getIdFromGraphQLId(resource.id),
        },
      });
    });
  });

  describe('when clicking on an item avatar', () => {
    beforeEach(async () => {
      createComponent();

      await findAvatar().vm.$emit('click');
    });

    it('navigates to the details page', () => {
      expect(routerPush).toHaveBeenCalledWith({
        name: CI_RESOURCE_DETAILS_PAGE_NAME,
        params: {
          id: getIdFromGraphQLId(resource.id),
        },
      });
    });
  });

  describe('statistics', () => {
    describe('when there are no statistics', () => {
      beforeEach(() => {
        createComponent({
          props: {
            resource: {
              forksCount: 0,
              starCount: 0,
            },
          },
        });
      });

      it('render favorites as 0', () => {
        expect(findFavorites().exists()).toBe(true);
        expect(findFavorites().text()).toBe('0');
      });

      it('render forks as 0', () => {
        expect(findForks().exists()).toBe(true);
        expect(findForks().text()).toBe('0');
      });
    });

    describe('where there are statistics', () => {
      beforeEach(() => {
        createComponent();
      });

      it('render favorites', () => {
        expect(findFavorites().exists()).toBe(true);
        expect(findFavorites().text()).toBe(String(defaultProps.resource.starCount));
      });

      it('render forks', () => {
        expect(findForks().exists()).toBe(true);
        expect(findForks().text()).toBe(String(defaultProps.resource.forksCount));
      });
    });
  });
});
