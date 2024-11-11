import { shallowMount } from '@vue/test-utils';
import { GlFormInput } from '@gitlab/ui';
import MergeScheduleInput from '~/merge_requests/components/merge_schedule_input.vue';

let wrapper;

function createComponent(propsData = {}) {
  wrapper = shallowMount(MergeScheduleInput, { propsData });
}

const findInput = () => wrapper.findComponent(GlFormInput);
const findHiddenInput = () => wrapper.find('input[type="hidden"]');

describe('Merge schedule input component', () => {
  it('Hides input if mergeAfter is undefined', () => {
    createComponent({ mergeAfter: undefined });

    expect(findInput().exists()).toBe(false);
    expect(findHiddenInput().exists()).toBe(true);
    expect([undefined, '']).toContain(findHiddenInput().attributes('value'));
  });

  it('Shows input if mergeAfter is set', () => {
    createComponent({ mergeAfter: '2024-10-27T20:40' });

    expect(findInput().exists()).toBe(true);
    expect(findHiddenInput().exists()).toBe(true);
    expect(findHiddenInput().attributes('value')).toBe('2024-10-27T20:40:00.000Z');
  });
});
