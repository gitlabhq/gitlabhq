import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';

import { mockMilestone } from 'jest/boards/mock_data';
import IssueMilestone from '~/vue_shared/components/issue/issue_milestone.vue';

const createComponent = (milestone = mockMilestone) => {
  const Component = Vue.extend(IssueMilestone);

  return shallowMount(Component, {
    propsData: {
      milestone,
    },
  });
};

describe('IssueMilestoneComponent', () => {
  let wrapper;
  let vm;

  beforeEach((done) => {
    wrapper = createComponent();

    ({ vm } = wrapper);

    Vue.nextTick(done);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('isMilestoneStarted', () => {
      it('should return `false` when milestoneStart prop is not defined', async () => {
        wrapper.setProps({
          milestone: { ...mockMilestone, start_date: '' },
        });
        await wrapper.vm.$nextTick();

        expect(wrapper.vm.isMilestoneStarted).toBe(false);
      });

      it('should return `true` when milestone start date is past current date', async () => {
        await wrapper.setProps({
          milestone: { ...mockMilestone, start_date: '1990-07-22' },
        });
        await wrapper.vm.$nextTick();

        expect(wrapper.vm.isMilestoneStarted).toBe(true);
      });
    });

    describe('isMilestonePastDue', () => {
      it('should return `false` when milestoneDue prop is not defined', async () => {
        wrapper.setProps({
          milestone: { ...mockMilestone, due_date: '' },
        });
        await wrapper.vm.$nextTick();

        expect(wrapper.vm.isMilestonePastDue).toBe(false);
      });

      it('should return `true` when milestone due is past current date', () => {
        wrapper.setProps({
          milestone: { ...mockMilestone, due_date: '1990-07-22' },
        });

        expect(wrapper.vm.isMilestonePastDue).toBe(true);
      });
    });

    describe('milestoneDatesAbsolute', () => {
      it('returns string containing absolute milestone due date', () => {
        expect(vm.milestoneDatesAbsolute).toBe('(December 31, 2019)');
      });

      it('returns string containing absolute milestone start date when due date is not present', async () => {
        wrapper.setProps({
          milestone: { ...mockMilestone, due_date: '' },
        });
        await wrapper.vm.$nextTick();

        expect(wrapper.vm.milestoneDatesAbsolute).toBe('(January 1, 2018)');
      });

      it('returns empty string when both milestone start and due dates are not present', async () => {
        wrapper.setProps({
          milestone: { ...mockMilestone, start_date: '', due_date: '' },
        });
        await wrapper.vm.$nextTick();

        expect(wrapper.vm.milestoneDatesAbsolute).toBe('');
      });
    });

    describe('milestoneDatesHuman', () => {
      it('returns string containing milestone due date when date is yet to be due', async () => {
        wrapper.setProps({
          milestone: { ...mockMilestone, due_date: `${new Date().getFullYear() + 10}-01-01` },
        });
        await wrapper.vm.$nextTick();

        expect(wrapper.vm.milestoneDatesHuman).toContain('years remaining');
      });

      it('returns string containing milestone start date when date has already started and due date is not present', async () => {
        wrapper.setProps({
          milestone: { ...mockMilestone, start_date: '1990-07-22', due_date: '' },
        });
        await wrapper.vm.$nextTick();

        expect(wrapper.vm.milestoneDatesHuman).toContain('Started');
      });

      it('returns string containing milestone start date when date is yet to start and due date is not present', async () => {
        wrapper.setProps({
          milestone: {
            ...mockMilestone,
            start_date: `${new Date().getFullYear() + 10}-01-01`,
            due_date: '',
          },
        });
        await wrapper.vm.$nextTick();

        expect(wrapper.vm.milestoneDatesHuman).toContain('Starts');
      });

      it('returns empty string when milestone start and due dates are not present', async () => {
        wrapper.setProps({
          milestone: { ...mockMilestone, start_date: '', due_date: '' },
        });
        await wrapper.vm.$nextTick();

        expect(wrapper.vm.milestoneDatesHuman).toBe('');
      });
    });
  });

  describe('template', () => {
    it('renders component root element with class `issue-milestone-details`', () => {
      expect(vm.$el.classList.contains('issue-milestone-details')).toBe(true);
    });

    it('renders milestone icon', () => {
      expect(wrapper.find(GlIcon).props('name')).toBe('clock');
    });

    it('renders milestone title', () => {
      expect(vm.$el.querySelector('.milestone-title').innerText.trim()).toBe(mockMilestone.title);
    });

    it('renders milestone tooltip', () => {
      expect(vm.$el.querySelector('.js-item-milestone').innerText.trim()).toContain(
        mockMilestone.title,
      );
    });
  });
});
