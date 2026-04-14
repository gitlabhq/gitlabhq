import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CodeQualityPage from '~/merge_requests/reports/pages/code_quality_page.vue';
import CodeQualityProvider from '~/merge_requests/reports/components/code_quality_provider.vue';
import CodeQualityContent from '~/merge_requests/reports/components/code_quality_content.vue';

describe('CodeQualityPage', () => {
  let wrapper;

  const DEFAULT_MR_PROP = { id: 1 };

  const findProvider = () => wrapper.findComponent(CodeQualityProvider);
  const findContent = () => wrapper.findComponent(CodeQualityContent);

  const createComponent = () => {
    wrapper = shallowMountExtended(CodeQualityPage, {
      propsData: {
        mr: DEFAULT_MR_PROP,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders CodeQualityProvider with mr prop', () => {
    expect(findProvider().props('mr')).toBe(DEFAULT_MR_PROP);
  });

  it('renders CodeQualityContent inside provider', () => {
    expect(findContent().exists()).toBe(true);
  });
});
