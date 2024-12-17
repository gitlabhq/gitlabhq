import { GlTableLite } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ProjectStorageDetail from '~/usage_quotas/storage/project/components/project_storage_detail.vue';
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

  const defaultProps = { storageTypes };

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      mount(ProjectStorageDetail, {
        propsData: {
          ...defaultProps,
          ...props,
        },
        provide: {
          containerRegistryPopoverContent: 'Sample popover message',
        },
      }),
    );
  };

  const findTable = () => wrapper.findComponent(GlTableLite);

  beforeEach(() => {
    createComponent();
  });

  describe('with storage types', () => {
    it.each(storageTypes)(
      'renders table row correctly %o',
      ({ id, name, value, description, helpPath, warning }) => {
        expect(wrapper.findByTestId(`${id}-name`).text()).toBe(name);
        expect(wrapper.findByTestId(`${id}-description`).text()).toBe(description);
        expect(wrapper.findByTestId(`${id}-icon`).props('name')).toBe(id);
        expect(wrapper.findByTestId(`${id}-help-link`).attributes('href')).toBe(helpPath);
        expect(wrapper.findByTestId(`${id}-value`).text()).toContain(numberToHumanSize(value, 1));

        expect(wrapper.findByTestId(`${id}-warning-icon`).exists()).toBe(Boolean(warning));
        expect(wrapper.findByTestId(`${id}-popover`).exists()).toBe(Boolean(warning));
      },
    );
  });

  describe('with details links', () => {
    it.each(storageTypes)('each $storageType.id', (item) => {
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
});
