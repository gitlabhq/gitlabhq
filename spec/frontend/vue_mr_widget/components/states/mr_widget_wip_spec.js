import Vue, { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import WorkInProgress from '~/vue_merge_request_widget/components/states/work_in_progress.vue';
import toast from '~/vue_shared/plugins/global_toast';
import eventHub from '~/vue_merge_request_widget/event_hub';

jest.mock('~/vue_shared/plugins/global_toast');

const createComponent = () => {
  const Component = Vue.extend(WorkInProgress);
  const mr = {
    title: 'The best MR ever',
    removeWIPPath: '/path/to/remove/wip',
  };
  const service = {
    removeWIP() {},
  };
  return new Component({
    el: document.createElement('div'),
    propsData: { mr, service },
  });
};

describe('Wip', () => {
  describe('props', () => {
    it('should have props', () => {
      const { mr, service } = WorkInProgress.props;

      expect(mr.type instanceof Object).toBeTruthy();
      expect(mr.required).toBeTruthy();

      expect(service.type instanceof Object).toBeTruthy();
      expect(service.required).toBeTruthy();
    });
  });

  describe('data', () => {
    it('should have default data', () => {
      const vm = createComponent();

      expect(vm.isMakingRequest).toBeFalsy();
    });
  });

  describe('methods', () => {
    const mrObj = {
      is_new_mr_data: true,
    };

    describe('handleRemoveDraft', () => {
      it('should make a request to service and handle response', async () => {
        const vm = createComponent();

        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
        jest.spyOn(vm.service, 'removeWIP').mockReturnValue(
          new Promise((resolve) => {
            resolve({
              data: mrObj,
            });
          }),
        );

        vm.handleRemoveDraft();

        await waitForPromises();

        expect(vm.isMakingRequest).toBeTruthy();
        expect(eventHub.$emit).toHaveBeenCalledWith('UpdateWidgetData', mrObj);
        expect(toast).toHaveBeenCalledWith('Marked as ready. Merging is now allowed.');
      });
    });
  });

  describe('template', () => {
    let vm;
    let el;

    beforeEach(() => {
      vm = createComponent();
      el = vm.$el;
    });

    it('should have correct elements', () => {
      expect(el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(el.innerText).toContain(
        "Merge blocked: merge request must be marked as ready. It's still marked as draft.",
      );
      expect(el.querySelector('.js-remove-draft').innerText.replace(/\s\s+/g, ' ')).toContain(
        'Mark as ready',
      );
    });

    it('should not show removeWIP button is user cannot update MR', async () => {
      vm.mr.removeWIPPath = '';

      await nextTick();

      expect(el.querySelector('.js-remove-draft')).toEqual(null);
    });
  });
});
