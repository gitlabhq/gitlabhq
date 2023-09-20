import { GlFormInputGroup } from '@gitlab/ui';
import { escape as esc } from 'lodash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'helpers/test_constants';
import EmbedDropdown from '~/snippets/components/embed_dropdown.vue';

const TEST_URL = `${TEST_HOST}/test/no">'xss`;

describe('snippets/components/embed_dropdown', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(EmbedDropdown, {
      propsData: {
        url: TEST_URL,
      },
    });
  };

  const findEmbedSection = () => wrapper.findByTestId('section-Embed');
  const findShareSection = () => wrapper.findByTestId('section-Share');

  it('renders dropdown items', () => {
    createComponent();

    const embedValue = `<script src="${esc(TEST_URL)}.js"></script>`;

    expect(findEmbedSection().text()).toBe('Embed');
    expect(findShareSection().text()).toBe('Share');
    expect(findEmbedSection().findComponent(GlFormInputGroup).attributes('value')).toBe(embedValue);
    expect(findShareSection().findComponent(GlFormInputGroup).attributes('value')).toBe(TEST_URL);
  });
});
