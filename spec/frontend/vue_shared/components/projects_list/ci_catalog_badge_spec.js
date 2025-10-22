import { GlPopover, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiCatalogBadge from '~/vue_shared/components/projects_list/ci_catalog_badge.vue';
import { helpPagePath } from '~/helpers/help_page_helper';

describe('CiCatalogBadge', () => {
  let wrapper;

  const defaultPropsData = {
    isPublished: false,
    exploreCatalogPath: '',
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(CiCatalogBadge, {
      propsData: { ...defaultPropsData, ...propsData },
      stubs: { GlSprintf },
    });
  };

  const findPublishedBadge = () => wrapper.findByTestId('ci-catalog-badge');
  const findUnpublishedBadge = () => wrapper.findByTestId('ci-catalog-badge-unpublished');
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findPopoverLink = () => wrapper.findComponent(GlLink);

  describe('when project is published', () => {
    const exploreCatalogPath = '/explore/catalog/my-project';

    beforeEach(() => {
      createComponent({
        propsData: {
          isPublished: true,
          exploreCatalogPath,
        },
      });
    });

    it('renders published badge with correct attributes', () => {
      expect(findPublishedBadge().attributes()).toMatchObject({
        icon: 'catalog-checkmark',
        variant: 'info',
        href: exploreCatalogPath,
      });
      expect(findPublishedBadge().text()).toBe('CI/CD Catalog');
    });

    it('does not render unpublished badge', () => {
      expect(findUnpublishedBadge().exists()).toBe(false);
    });
  });

  describe('when project is not published', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          isPublished: false,
        },
      });
    });

    it('renders unpublished badge with correct attributes', () => {
      expect(findUnpublishedBadge().attributes()).toMatchObject({
        icon: 'catalog-checkmark',
        variant: 'warning',
      });
      expect(findUnpublishedBadge().text()).toContain('CI/CD Catalog (unpublished)');
    });

    it('does not render published badge', () => {
      expect(findPublishedBadge().exists()).toBe(false);
    });

    it('renders popover with correct title', () => {
      expect(findPopover().props('title')).toBe('Catalog project (unpublished)');
    });

    it('renders popover help link with correct href', () => {
      const expectedHref = helpPagePath('ci/components/_index.md', {
        anchor: 'publish-a-new-release',
      });

      expect(findPopoverLink().attributes('href')).toBe(expectedHref);
      expect(findPopoverLink().text()).toBe('Learn how to publish a new release');
    });

    it('renders popover description text', () => {
      expect(findPopover().text()).toContain(
        'This project is set as a Catalog project, but has not yet been published',
      );
    });
  });

  describe('when exploreCatalogPath is not provided', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          isPublished: true,
          exploreCatalogPath: '',
        },
      });
    });

    it('renders badge without href', () => {
      expect(findPublishedBadge().attributes('href')).toBe('');
    });
  });
});
