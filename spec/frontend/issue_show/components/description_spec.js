import $ from 'jquery';
import Vue from 'vue';
import '~/behaviors/markdown/render_gfm';
import mountComponent from 'helpers/vue_mount_component_helper';
import { TEST_HOST } from 'helpers/test_constants';
import Description from '~/issue_show/components/description.vue';
import TaskList from '~/task_list';

jest.mock('~/task_list');

describe('Description component', () => {
  let vm;
  let DescriptionComponent;
  const props = {
    canUpdate: true,
    descriptionHtml: 'test',
    descriptionText: 'test',
    updatedAt: new Date().toString(),
    taskStatus: '',
    updateUrl: TEST_HOST,
  };

  beforeEach(() => {
    DescriptionComponent = Vue.extend(Description);

    if (!document.querySelector('.issuable-meta')) {
      const metaData = document.createElement('div');
      metaData.classList.add('issuable-meta');
      metaData.innerHTML =
        '<div class="flash-container"></div><span id="task_status"></span><span id="task_status_short"></span>';

      document.body.appendChild(metaData);
    }

    vm = mountComponent(DescriptionComponent, props);
  });

  afterEach(() => {
    vm.$destroy();
  });

  afterAll(() => {
    $('.issuable-meta .flash-container').remove();
  });

  it('animates description changes', () => {
    vm.descriptionHtml = 'changed';

    return vm
      .$nextTick()
      .then(() => {
        expect(
          vm.$el.querySelector('.md').classList.contains('issue-realtime-pre-pulse'),
        ).toBeTruthy();
        jest.runAllTimers();
        return vm.$nextTick();
      })
      .then(() => {
        expect(
          vm.$el.querySelector('.md').classList.contains('issue-realtime-trigger-pulse'),
        ).toBeTruthy();
      });
  });

  it('opens reCAPTCHA dialog if update rejected as spam', () => {
    let modal;
    const recaptchaChild = vm.$children.find(
      // eslint-disable-next-line no-underscore-dangle
      child => child.$options._componentTag === 'recaptcha-modal',
    );

    recaptchaChild.scriptSrc = '//scriptsrc';

    vm.taskListUpdateSuccess({
      recaptcha_html: '<div class="g-recaptcha">recaptcha_html</div>',
    });

    return vm
      .$nextTick()
      .then(() => {
        modal = vm.$el.querySelector('.js-recaptcha-modal');

        expect(modal.style.display).not.toEqual('none');
        expect(modal.querySelector('.g-recaptcha').textContent).toEqual('recaptcha_html');
        expect(document.body.querySelector('.js-recaptcha-script').src).toMatch('//scriptsrc');
      })
      .then(() => modal.querySelector('.close').click())
      .then(() => vm.$nextTick())
      .then(() => {
        expect(modal.style.display).toEqual('none');
        expect(document.body.querySelector('.js-recaptcha-script')).toBeNull();
      });
  });

  it('applies syntax highlighting and math when description changed', () => {
    const vmSpy = jest.spyOn(vm, 'renderGFM');
    const prototypeSpy = jest.spyOn($.prototype, 'renderGFM');
    vm.descriptionHtml = 'changed';

    return vm.$nextTick().then(() => {
      expect(vm.$refs['gfm-content']).toBeDefined();
      expect(vmSpy).toHaveBeenCalled();
      expect(prototypeSpy).toHaveBeenCalled();
      expect($.prototype.renderGFM).toHaveBeenCalled();
    });
  });

  it('sets data-update-url', () => {
    expect(vm.$el.querySelector('textarea').dataset.updateUrl).toEqual(TEST_HOST);
  });

  describe('TaskList', () => {
    beforeEach(() => {
      vm.$destroy();
      TaskList.mockClear();
      vm = mountComponent(DescriptionComponent, { ...props, issuableType: 'issuableType' });
    });

    it('re-inits the TaskList when description changed', () => {
      vm.descriptionHtml = 'changed';

      expect(TaskList).toHaveBeenCalled();
    });

    it('does not re-init the TaskList when canUpdate is false', () => {
      vm.canUpdate = false;
      vm.descriptionHtml = 'changed';

      expect(TaskList).toHaveBeenCalledTimes(1);
    });

    it('calls with issuableType dataType', () => {
      vm.descriptionHtml = 'changed';

      expect(TaskList).toHaveBeenCalledWith({
        dataType: 'issuableType',
        fieldName: 'description',
        selector: '.detail-page-description',
        onSuccess: expect.any(Function),
        onError: expect.any(Function),
        lockVersion: 0,
      });
    });
  });

  describe('taskStatus', () => {
    it('adds full taskStatus', () => {
      vm.taskStatus = '1 of 1';

      return vm.$nextTick().then(() => {
        expect(document.querySelector('.issuable-meta #task_status').textContent.trim()).toBe(
          '1 of 1',
        );
      });
    });

    it('adds short taskStatus', () => {
      vm.taskStatus = '1 of 1';

      return vm.$nextTick().then(() => {
        expect(document.querySelector('.issuable-meta #task_status_short').textContent.trim()).toBe(
          '1/1 task',
        );
      });
    });

    it('clears task status text when no tasks are present', () => {
      vm.taskStatus = '0 of 0';

      return vm.$nextTick().then(() => {
        expect(document.querySelector('.issuable-meta #task_status').textContent.trim()).toBe('');
      });
    });
  });

  describe('taskListUpdateError', () => {
    it('should create flash notification and emit an event to parent', () => {
      const msg =
        'Someone edited this issue at the same time you did. The description has been updated and you will need to make your changes again.';
      const spy = jest.spyOn(vm, '$emit');

      vm.taskListUpdateError();

      expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(msg);
      expect(spy).toHaveBeenCalledWith('taskListUpdateFailed');
    });
  });
});
