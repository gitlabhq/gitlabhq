import { escape as esc } from 'lodash';
import { mount } from '@vue/test-utils';
import { GlFormInputGroup } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import EmbedDropdown from '~/snippets/components/embed_dropdown.vue';

const TEST_URL = `${TEST_HOST}/test/no">'xss`;

describe('snippets/components/embed_dropdown', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mount(EmbedDropdown, {
      propsData: {
        url: TEST_URL,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findSectionsData = () => {
    const sections = [];
    let current = {};

    wrapper.findAll('[data-testid="header"],[data-testid="input"]').wrappers.forEach(x => {
      const type = x.attributes('data-testid');

      if (type === 'header') {
        current = {
          header: x.text(),
        };

        sections.push(current);
      } else {
        const value = x.find(GlFormInputGroup).props('value');
        const copyValue = x.find('button[title="Copy"]').attributes('data-clipboard-text');

        Object.assign(current, {
          value,
          copyValue,
        });
      }
    });

    return sections;
  };

  it('renders dropdown items', () => {
    createComponent();

    const embedValue = `<script src="${esc(TEST_URL)}.js"></script>`;

    expect(findSectionsData()).toEqual([
      {
        header: 'Embed',
        value: embedValue,
        copyValue: embedValue,
      },
      {
        header: 'Share',
        value: TEST_URL,
        copyValue: TEST_URL,
      },
    ]);
  });
});
