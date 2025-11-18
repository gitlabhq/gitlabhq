import { GlSearchBoxByClick } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import SearchBox from '~/pages/experimental/o11y_service_settings/search_box.vue';

jest.mock('~/lib/utils/url_utility', () => {
  const urlUtils = jest.requireActual('~/lib/utils/url_utility');
  return {
    ...urlUtils,
    visitUrl: jest.fn(),
  };
});

describe('O11yServiceSettingsSearchBox', () => {
  let wrapper;
  const defaultProps = {
    searchUrl: '/experimental/o11y_service_settings',
    placeholder: 'Filter by group ID',
  };

  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByClick);

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(SearchBox, {
      propsData: { ...defaultProps, ...props },
    });
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders search box with correct props', () => {
    createComponent({ initialValue: '12345' });

    expect(findSearchBox().props()).toMatchObject({
      placeholder: defaultProps.placeholder,
      value: '12345',
    });
  });

  describe('onSubmit', () => {
    it('navigates with group_id param', async () => {
      createComponent();
      await findSearchBox().vm.$emit('input', '12345');
      await findSearchBox().vm.$emit('submit');

      expect(visitUrl).toHaveBeenCalledWith('/experimental/o11y_service_settings?group_id=12345');
    });

    it('uses & separator when URL has existing params', async () => {
      createComponent({ searchUrl: '/experimental/o11y_service_settings?other=value' });
      await findSearchBox().vm.$emit('input', '12345');
      await findSearchBox().vm.$emit('submit');

      expect(visitUrl).toHaveBeenCalledWith(
        '/experimental/o11y_service_settings?other=value&group_id=12345',
      );
    });

    it('navigates to base URL when search term is empty', async () => {
      createComponent();
      await findSearchBox().vm.$emit('submit');

      expect(visitUrl).toHaveBeenCalledWith('/experimental/o11y_service_settings');
    });

    it('encodes special characters in search term', async () => {
      createComponent();
      await findSearchBox().vm.$emit('input', 'test & value');
      await findSearchBox().vm.$emit('submit');

      expect(visitUrl).toHaveBeenCalledWith(
        '/experimental/o11y_service_settings?group_id=test%20%26%20value',
      );
    });
  });

  describe('onClear', () => {
    it('clears search term and navigates to base URL', async () => {
      createComponent({ initialValue: '12345' });
      await findSearchBox().vm.$emit('clear');

      expect(findSearchBox().props('value')).toBe('');
      expect(visitUrl).toHaveBeenCalledWith('/experimental/o11y_service_settings');
    });
  });
});
