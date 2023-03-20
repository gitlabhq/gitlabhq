import { mount } from '@vue/test-utils';
import TokenedInput from '~/ide/components/shared/tokened_input.vue';

const TEST_PLACEHOLDER = 'Searching in test';
const TEST_TOKENS = [
  { label: 'lorem', id: 1 },
  { label: 'ipsum', id: 2 },
  { label: 'dolar', id: 3 },
];
const TEST_VALUE = 'lorem';

function getTokenElements(wrapper) {
  return wrapper.findAll('.filtered-search-token button');
}

describe('IDE shared/TokenedInput', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(TokenedInput, {
      propsData: {
        tokens: TEST_TOKENS,
        placeholder: TEST_PLACEHOLDER,
        value: TEST_VALUE,
        ...props,
      },
      attachTo: document.body,
    });
  };

  it('renders tokens', () => {
    createComponent();
    const renderedTokens = getTokenElements(wrapper).wrappers.map((w) => w.text());

    expect(renderedTokens).toEqual(TEST_TOKENS.map((x) => x.label));
  });

  it('renders input', () => {
    createComponent();

    expect(wrapper.find('input').element).toBeInstanceOf(HTMLInputElement);
    expect(wrapper.find('input').element).toHaveValue(TEST_VALUE);
  });

  it('renders placeholder, when tokens are empty', () => {
    createComponent({ tokens: [] });

    expect(wrapper.find('input').attributes('placeholder')).toBe(TEST_PLACEHOLDER);
  });

  it('triggers "removeToken" on token click', async () => {
    createComponent();
    await getTokenElements(wrapper).at(0).trigger('click');

    expect(wrapper.emitted('removeToken')[0]).toStrictEqual([TEST_TOKENS[0]]);
  });

  it('removes token on backspace when value is empty', async () => {
    createComponent({ value: '' });

    expect(wrapper.emitted('removeToken')).toBeUndefined();

    await wrapper.find('input').trigger('keyup.delete');
    await wrapper.find('input').trigger('keyup.delete');

    expect(wrapper.emitted('removeToken')[0]).toStrictEqual([TEST_TOKENS[TEST_TOKENS.length - 1]]);
  });

  it('does not trigger "removeToken" on backspaces when value is not empty', async () => {
    createComponent({ value: 'SOMETHING' });

    await wrapper.find('input').trigger('keyup.delete');
    await wrapper.find('input').trigger('keyup.delete');

    expect(wrapper.emitted('removeToken')).toBeUndefined();
  });

  it('does not trigger "removeToken" on backspaces when tokens are empty', async () => {
    createComponent({ value: '', tokens: [] });

    await wrapper.find('input').trigger('keyup.delete');
    await wrapper.find('input').trigger('keyup.delete');

    expect(wrapper.emitted('removeToken')).toBeUndefined();
  });

  it('triggers "focus" on input focus', async () => {
    createComponent();

    await wrapper.find('input').trigger('focus');

    expect(wrapper.emitted('focus')).toHaveLength(1);
  });

  it('triggers "blur" on input blur', async () => {
    createComponent();

    await wrapper.find('input').trigger('blur');

    expect(wrapper.emitted('blur')).toHaveLength(1);
  });

  it('triggers "input" with value on input change', async () => {
    createComponent();

    await wrapper.find('input').setValue('something-else');

    expect(wrapper.emitted('input')[0]).toStrictEqual(['something-else']);
  });
});
