import { GlTableLite } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ProjectStorageDetail from '~/usage_quotas/storage/project/components/project_storage_detail.vue';
import RepositoryHealthDetailsSection from '~/usage_quotas/storage/project/components/repository_health_details/repository_health_details_section.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';

describe('ProjectStorageDetail', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const generateStorageType = (props) => {
    return {
      id: 'id',
      name: 'name',
      description: 'description',
      helpPath: '/help-path',
      detailsPath: '/details-link',
      value: 42,
      ...props,
    };
  };

  const storageTypes = [
    generateStorageType({ id: 'one' }),
    generateStorageType({ id: 'two' }),
    generateStorageType({
      id: 'three',
      warning: {
        content: 'warning message',
      },
    }),
  ];

  const STORAGE_TYPE_WITH_DETAILS = generateStorageType({ id: 'repository', value: 100 });
  const STORAGE_TYPE_WITHOUT_DETAILS = generateStorageType({ id: 'one' });

  const defaultProps = { storageTypes };

  const createComponent = (props = {}, features = {}) => {
    wrapper = extendedWrapper(
      mount(ProjectStorageDetail, {
        propsData: {
          ...defaultProps,
          ...props,
        },
        provide: {
          containerRegistryPopoverContent: 'Sample popover message',
          glFeatures: {
            projectRepositoriesHealthUi: false,
            ...features,
          },
        },
      }),
    );
  };

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findShowDetailsButton = (id) => wrapper.findByTestId(`${id}-show-details-button`);
  const findRowDetails = () => wrapper.findComponent(RepositoryHealthDetailsSection);
  const findRowData = () => wrapper.findByTestId('storage-type-row').find('td');

  beforeEach(() => {
    createComponent();
  });

  describe('with storage types', () => {
    it.each(storageTypes)(
      'renders table row correctly for id $id',
      ({ id, name, value, description, helpPath, warning }) => {
        expect(wrapper.findByTestId(`${id}-name`).text()).toBe(name);
        expect(wrapper.findByTestId(`${id}-description`).text()).toContain(description);
        expect(wrapper.findByTestId(`${id}-icon`).props('name')).toBe(id);
        expect(wrapper.findByTestId(`${id}-help-link`).attributes('href')).toBe(helpPath);
        expect(wrapper.findByTestId(`${id}-help-link`).text()).toBe('Learn more.');
        expect(wrapper.findByTestId(`${id}-value`).text()).toContain(numberToHumanSize(value, 1));
        expect(wrapper.findByTestId(`${id}-warning-icon`).exists()).toBe(Boolean(warning));
        expect(wrapper.findByTestId(`${id}-popover`).exists()).toBe(Boolean(warning));
      },
    );
  });

  describe('with details links', () => {
    it.each(storageTypes)('renders correctly for id $id', (item) => {
      const shouldExist = Boolean(item.detailsPath && item.value);
      const detailsLink = wrapper.findByTestId(`${item.id}-details-link`);
      expect(detailsLink.exists()).toBe(shouldExist);
    });
  });

  describe('without storage types', () => {
    beforeEach(() => {
      createComponent({ storageTypes: [] });
    });

    it('should render the table header <th>', () => {
      expect(findTable().find('th').exists()).toBe(true);
    });

    it('should not render any table data <td>', () => {
      expect(findTable().find('td').exists()).toBe(false);
    });
  });

  describe('storage types with details components', () => {
    describe('when feature flag is enabled', () => {
      beforeEach(() => {
        createComponent(
          { storageTypes: [STORAGE_TYPE_WITH_DETAILS, STORAGE_TYPE_WITHOUT_DETAILS] },
          { projectRepositoriesHealthUi: true },
        );
      });

      it('renders show details button only for storage type with details component', () => {
        expect(findShowDetailsButton(STORAGE_TYPE_WITH_DETAILS.id).exists()).toBe(true);
        expect(findShowDetailsButton(STORAGE_TYPE_WITHOUT_DETAILS.id).exists()).toBe(false);
      });
    });

    describe('when feature flag is disabled', () => {
      beforeEach(() => {
        createComponent(
          { storageTypes: [STORAGE_TYPE_WITH_DETAILS, STORAGE_TYPE_WITHOUT_DETAILS] },
          { projectRepositoriesHealthUi: false },
        );
      });

      it('does not render show details button for any storage types', () => {
        expect(findShowDetailsButton(STORAGE_TYPE_WITH_DETAILS.id).exists()).toBe(false);
        expect(findShowDetailsButton(STORAGE_TYPE_WITHOUT_DETAILS.id).exists()).toBe(false);
      });
    });

    describe('toggling show details component', () => {
      const toggleDetailsSection = async () => {
        findShowDetailsButton(STORAGE_TYPE_WITH_DETAILS.id).vm.$emit('click');
        await nextTick();
      };

      beforeEach(() => {
        createComponent(
          { storageTypes: [STORAGE_TYPE_WITH_DETAILS] },
          { projectRepositoriesHealthUi: true },
        );
      });

      it('toggles the details component when the button is clicked', async () => {
        expect(findRowDetails().exists()).toBe(false);
        await toggleDetailsSection();
        expect(findRowDetails().exists()).toBe(true);
        await toggleDetailsSection();
        expect(findRowDetails().exists()).toBe(false);
      });

      it('toggles the chevron direction when the button is clicked', async () => {
        expect(findShowDetailsButton(STORAGE_TYPE_WITH_DETAILS.id).props('icon')).toBe(
          'chevron-right',
        );
        await toggleDetailsSection();
        expect(findShowDetailsButton(STORAGE_TYPE_WITH_DETAILS.id).props('icon')).toBe(
          'chevron-down',
        );
        await toggleDetailsSection();
        expect(findShowDetailsButton(STORAGE_TYPE_WITH_DETAILS.id).props('icon')).toBe(
          'chevron-right',
        );
      });

      it('toggles the row bottom border when the button is clicked', async () => {
        expect(findRowData().classes('!gl-border-b-0')).toBe(false);
        await toggleDetailsSection();
        expect(findRowData().classes('!gl-border-b-0')).toBe(true);
        await toggleDetailsSection();
        expect(findRowData().classes('!gl-border-b-0')).toBe(false);
      });
    });
  });
});
