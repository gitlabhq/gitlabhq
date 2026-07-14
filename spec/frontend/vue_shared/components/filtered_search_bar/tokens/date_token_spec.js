import { GlDatepicker, GlFilteredSearchToken } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import DateToken from '~/vue_shared/components/filtered_search_bar/tokens/date_token.vue';

const propsData = {
  active: true,
  config: {},
  value: { operator: '>', data: null },
};

function createComponent() {
  return mount(DateToken, {
    propsData,
    provide: {
      portalName: 'fake target',
      alignSuggestions: function fakeAlignSuggestions() {},
      termsAsTokens: () => false,
    },
  });
}

describe('DateToken', () => {
  let wrapper;

  const findGlFilteredSearchToken = () => wrapper.findComponent(GlFilteredSearchToken);
  const findDatepicker = () => wrapper.findComponent(GlDatepicker);

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('renders GlDatepicker', () => {
    expect(findDatepicker().exists()).toBe(true);
  });

  it('renders GlFilteredSearchToken', () => {
    expect(findGlFilteredSearchToken().exists()).toBe(true);
  });

  it('emits `complete` and `select` with the formatted date when a value is selected', () => {
    findDatepicker().vm.$emit('input', new Date('October 13, 2014 11:13:00'));
    findDatepicker().vm.$emit('close');

    expect(findGlFilteredSearchToken().emitted()).toEqual({
      complete: [['2014-10-13']],
      select: [['2014-10-13']],
    });
  });
  it('submits the date when Tab key is pressed', () => {
    findDatepicker().vm.$emit('input', new Date('October 13, 2014 11:13:00'));
    findDatepicker().vm.$emit('keydown', { key: 'Tab', target: { value: '2014-10-13' } });

    expect(findGlFilteredSearchToken().emitted()).toMatchObject({
      complete: [['2014-10-13']],
      select: [['2014-10-13']],
    });
  });

  it('does not reappear after date is cleared with Backspace', () => {
    findDatepicker().vm.$emit('input', new Date('October 13, 2014 11:13:00'));
    findDatepicker().vm.$emit('keydown', { key: 'Backspace', target: { value: '' } });
    findDatepicker().vm.$emit('close');

    expect(findGlFilteredSearchToken().emitted('complete')).toBeUndefined();
    expect(findGlFilteredSearchToken().emitted('select')).toBeUndefined();
  });

  it('prevents Tab key from deactivating the token on datepicker input', () => {
    const input = wrapper.element.querySelector('#glfs-datepicker');
    const event = new KeyboardEvent('keydown', { key: 'Tab', bubbles: true, cancelable: true });
    input.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(true);
  });

  it('clears the date when Backspace is pressed on datepicker input', () => {
    findDatepicker().vm.$emit('input', new Date('October 13, 2014 11:13:00'));
    const input = wrapper.element.querySelector('#glfs-datepicker');
    const event = new KeyboardEvent('keydown', { key: 'Backspace', bubbles: true });
    input.dispatchEvent(event);
    findDatepicker().vm.$emit('close');

    expect(findGlFilteredSearchToken().emitted('complete')).toBeUndefined();
    expect(findGlFilteredSearchToken().emitted('select')).toBeUndefined();
  });
});
