import Vue from 'vue';
import JobDetail from '~/ide/components/jobs/detail.vue';
import { createStore } from '~/ide/stores';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { jobs } from '../../mock_data';
import { TEST_HOST } from 'helpers/test_constants';

describe('IDE jobs detail view', () => {
  let vm;

  const createComponent = () => {
    const store = createStore();

    store.state.pipelines.detailJob = {
      ...jobs[0],
      isLoading: true,
      output: 'testing',
      rawPath: `${TEST_HOST}/raw`,
    };

    return createComponentWithStore(Vue.extend(JobDetail), store);
  };

  beforeEach(() => {
    vm = createComponent();

    jest.spyOn(vm, 'fetchJobTrace').mockResolvedValue();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('mounted', () => {
    beforeEach(() => {
      vm = vm.$mount();
    });

    it('calls fetchJobTrace', () => {
      expect(vm.fetchJobTrace).toHaveBeenCalled();
    });

    it('scrolls to bottom', () => {
      expect(vm.$refs.buildTrace.scrollTo).toHaveBeenCalled();
    });

    it('renders job output', () => {
      expect(vm.$el.querySelector('.bash').textContent).toContain('testing');
    });

    it('renders empty message output', done => {
      vm.$store.state.pipelines.detailJob.output = '';

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.bash').textContent).toContain('No messages were logged');

        done();
      });
    });

    it('renders loading icon', () => {
      expect(vm.$el.querySelector('.build-loader-animation')).not.toBe(null);
      expect(vm.$el.querySelector('.build-loader-animation').style.display).toBe('');
    });

    it('hides output when loading', () => {
      expect(vm.$el.querySelector('.bash')).not.toBe(null);
      expect(vm.$el.querySelector('.bash').style.display).toBe('none');
    });

    it('hide loading icon when isLoading is false', done => {
      vm.$store.state.pipelines.detailJob.isLoading = false;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.build-loader-animation').style.display).toBe('none');

        done();
      });
    });

    it('resets detailJob when clicking header button', () => {
      jest.spyOn(vm, 'setDetailJob').mockImplementation();

      vm.$el.querySelector('.btn').click();

      expect(vm.setDetailJob).toHaveBeenCalledWith(null);
    });

    it('renders raw path link', () => {
      expect(vm.$el.querySelector('.controllers-buttons').getAttribute('href')).toBe(
        `${TEST_HOST}/raw`,
      );
    });
  });

  describe('scroll buttons', () => {
    beforeEach(() => {
      vm = createComponent();
      jest.spyOn(vm, 'fetchJobTrace').mockResolvedValue();
    });

    afterEach(() => {
      vm.$destroy();
    });

    it.each`
      fnName          | btnName   | scrollPos
      ${'scrollDown'} | ${'down'} | ${0}
      ${'scrollUp'}   | ${'up'}   | ${1}
    `('triggers $fnName when clicking $btnName button', ({ fnName, scrollPos }) => {
      jest.spyOn(vm, fnName).mockImplementation();

      vm = vm.$mount();

      vm.scrollPos = scrollPos;

      return vm.$nextTick().then(() => {
        vm.$el.querySelector('.btn-scroll:not([disabled])').click();
        expect(vm[fnName]).toHaveBeenCalled();
      });
    });
  });

  describe('scrollDown', () => {
    beforeEach(() => {
      vm = vm.$mount();

      jest.spyOn(vm.$refs.buildTrace, 'scrollTo').mockImplementation();
    });

    it('scrolls build trace to bottom', () => {
      jest.spyOn(vm.$refs.buildTrace, 'scrollHeight', 'get').mockReturnValue(1000);

      vm.scrollDown();

      expect(vm.$refs.buildTrace.scrollTo).toHaveBeenCalledWith(0, 1000);
    });
  });

  describe('scrollUp', () => {
    beforeEach(() => {
      vm = vm.$mount();

      jest.spyOn(vm.$refs.buildTrace, 'scrollTo').mockImplementation();
    });

    it('scrolls build trace to top', () => {
      vm.scrollUp();

      expect(vm.$refs.buildTrace.scrollTo).toHaveBeenCalledWith(0, 0);
    });
  });

  describe('scrollBuildLog', () => {
    beforeEach(() => {
      vm = vm.$mount();
      jest.spyOn(vm.$refs.buildTrace, 'scrollTo').mockImplementation();
      jest.spyOn(vm.$refs.buildTrace, 'offsetHeight', 'get').mockReturnValue(100);
      jest.spyOn(vm.$refs.buildTrace, 'scrollHeight', 'get').mockReturnValue(200);
    });

    it('sets scrollPos to bottom when at the bottom', () => {
      jest.spyOn(vm.$refs.buildTrace, 'scrollTop', 'get').mockReturnValue(100);

      vm.scrollBuildLog();

      expect(vm.scrollPos).toBe(1);
    });

    it('sets scrollPos to top when at the top', () => {
      jest.spyOn(vm.$refs.buildTrace, 'scrollTop', 'get').mockReturnValue(0);
      vm.scrollPos = 1;

      vm.scrollBuildLog();

      expect(vm.scrollPos).toBe(0);
    });

    it('resets scrollPos when not at top or bottom', () => {
      jest.spyOn(vm.$refs.buildTrace, 'scrollTop', 'get').mockReturnValue(10);

      vm.scrollBuildLog();

      expect(vm.scrollPos).toBe('');
    });
  });
});
