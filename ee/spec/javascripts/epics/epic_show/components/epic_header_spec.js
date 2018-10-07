import Vue from 'vue';
import epicHeader from 'ee/epics/epic_show/components/epic_header.vue';
import { stateEvent } from 'ee/epics/constants';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { headerProps } from '../mock_data';

describe('epicHeader', () => {
  let vm;
  const { author } = headerProps;

  beforeEach(() => {
    const EpicHeader = Vue.extend(epicHeader);
    vm = mountComponent(EpicHeader, headerProps);
  });

  it('should render timeago tooltip', () => {
    expect(vm.$el.querySelector('time')).toBeDefined();
  });

  it('should link to author url', () => {
    expect(vm.$el.querySelector('a').href).toEqual(author.url);
  });

  it('should render author avatar', () => {
    expect(vm.$el.querySelector('img').src).toEqual(`${author.src}?width=24`);
  });

  it('should render author name', () => {
    expect(vm.$el.querySelector('.user-avatar-link').innerText.trim()).toEqual(author.name);
  });

  it('should render username tooltip', () => {
    expect(vm.$el.querySelector('.user-avatar-link span').dataset.originalTitle).toEqual(
      author.username,
    );
  });

  it('should render sidebar toggle button', () => {
    expect(vm.$el.querySelector('button.js-sidebar-toggle')).not.toBe(null);
  });

  it('should render status badge', () => {
    const badgeEl = vm.$el.querySelector('.issuable-status-box');
    const badgeIconEl = badgeEl.querySelector('svg use');
    expect(badgeEl).not.toBe(null);
    expect(badgeEl.innerText.trim()).toBe('Open');
    expect(badgeIconEl.getAttribute('xlink:href')).toContain('issue-open-m');
  });

  it('should render `Close epic` button when `isEpicOpen` & `canUpdate` props are true', () => {
    vm.isEpicOpen = true;
    const closeButtonEl = vm.$el.querySelector('.js-issuable-actions .js-btn-epic-action');
    expect(closeButtonEl).not.toBe(null);
    expect(closeButtonEl.innerText.trim()).toBe('Close epic');
  });

  describe('computed', () => {
    describe('statusIcon', () => {
      it('returns `issue-open-m` when `isEpicOpen` prop is true', () => {
        vm.isEpicOpen = true;
        expect(vm.statusIcon).toBe('issue-open-m');
      });

      it('returns `mobile-issue-close` when `isEpicOpen` prop is false', () => {
        vm.isEpicOpen = false;
        expect(vm.statusIcon).toBe('mobile-issue-close');
      });
    });

    describe('statusText', () => {
      it('returns `Open` when `isEpicOpen` prop is true', () => {
        vm.isEpicOpen = true;
        expect(vm.statusText).toBe('Open');
      });

      it('returns `Closed` when `isEpicOpen` prop is false', () => {
        vm.isEpicOpen = false;
        expect(vm.statusText).toBe('Closed');
      });
    });

    describe('actionButtonClass', () => {
      it('returns classes `btn btn-grouped js-btn-epic-action qa-close-reopen-epic-button` & `btn-close` when `isEpicOpen` prop is true', () => {
        vm.isEpicOpen = true;
        expect(vm.actionButtonClass).toContain('btn btn-grouped js-btn-epic-action qa-close-reopen-epic-button btn-close');
      });

      it('returns classes `btn btn-grouped js-btn-epic-action qa-close-reopen-epic-button` & `btn-open` when `isEpicOpen` prop is false', () => {
        vm.isEpicOpen = false;
        expect(vm.actionButtonClass).toContain('btn btn-grouped js-btn-epic-action qa-close-reopen-epic-button btn-open');
      });
    });

    describe('actionButtonText', () => {
      it('returns `Close epic` when `isEpicOpen` prop is true', () => {
        vm.isEpicOpen = true;
        expect(vm.actionButtonText).toBe('Close epic');
      });

      it('returns `Reopen epic` when `isEpicOpen` prop is false', () => {
        vm.isEpicOpen = false;
        expect(vm.actionButtonText).toBe('Reopen epic');
      });
    });
  });

  describe('methods', () => {
    describe('toggleStatus', () => {
      it('emits `toggleEpicStatus` on component with stateEventType param as `close` when `isEpicOpen` prop is true', () => {
        spyOn(vm, '$emit');

        vm.isEpicOpen = true;
        vm.toggleStatus();
        expect(vm.statusUpdating).toBe(true);
        expect(vm.$emit).toHaveBeenCalledWith('toggleEpicStatus', stateEvent.close);
      });

      it('emits `toggleEpicStatus` on component with stateEventType param as `reopen` when `isEpicOpen` prop is false', () => {
        spyOn(vm, '$emit');

        vm.isEpicOpen = false;
        vm.toggleStatus();
        expect(vm.statusUpdating).toBe(true);
        expect(vm.$emit).toHaveBeenCalledWith('toggleEpicStatus', stateEvent.reopen);
      });
    });
  });
});
