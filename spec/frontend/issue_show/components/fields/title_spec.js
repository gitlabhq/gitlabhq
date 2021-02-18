import { shallowMount } from '@vue/test-utils';
import TitleField from '~/issue_show/components/fields/title.vue';
import eventHub from '~/issue_show/event_hub';

describe('Title field component', () => {
  let wrapper;

  const findInput = () => wrapper.find({ ref: 'input' });

  beforeEach(() => {
    jest.spyOn(eventHub, '$emit');

    wrapper = shallowMount(TitleField, {
      propsData: {
        formState: {
          title: 'test',
        },
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders form control with formState title', () => {
    expect(findInput().element.value).toBe('test');
  });

  it('triggers update with meta+enter', () => {
    findInput().trigger('keydown.enter', { metaKey: true });

    expect(eventHub.$emit).toHaveBeenCalledWith('update.issuable');
  });

  it('triggers update with ctrl+enter', () => {
    findInput().trigger('keydown.enter', { ctrlKey: true });

    expect(eventHub.$emit).toHaveBeenCalledWith('update.issuable');
  });
});
