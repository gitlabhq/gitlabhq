// This spec inspects the console calls it collects, so it must not throw on the first one.
/* eslint-disable import/no-deprecated */
import { shallowMount } from '@vue/test-utils';
import {
  forgetConsoleCalls,
  getConsoleCalls,
  useConsoleWatcherThrowsImmediately,
} from 'helpers/console_watcher';

const VueRenderWarningsComponent = {
  name: 'VueRenderWarningsComponent',
  props: {
    readUndefinedProperty: {
      type: Boolean,
      required: false,
      default: false,
    },
    readRunWithContext: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return { definedProperty: 'defined' };
  },
  template: `
    <div>
      <span v-if="readUndefinedProperty">{{ notDefinedAnywhere }}</span>
      <span v-else-if="readRunWithContext">{{ runWithContext }}</span>
      <span v-else>{{ definedProperty }}</span>
    </div>
  `,
};

describe('Vue render warnings', () => {
  useConsoleWatcherThrowsImmediately(false);

  afterEach(() => {
    forgetConsoleCalls();
  });

  describe('when an assertion over a Vue instance fails', () => {
    it('reports the assertion instead of Jest probing the instance', () => {
      const { vm } = shallowMount(VueRenderWarningsComponent);
      const spy = jest.fn();
      spy(vm);

      let message = '';
      try {
        expect(spy).toHaveBeenCalledWith({ neverCalledWithThis: true });
      } catch (error) {
        message = error.message;
      }

      // Jest lays the diff out differently under `--ci`, so assert on its payload.
      expect(message).toContain('neverCalledWithThis');
      expect(message).not.toContain('Unexpected calls to console');
      expect(getConsoleCalls()).toEqual([]);
    });
  });

  describe('when a template reads a property the instance does not define', () => {
    it('reports the warning, naming the property', () => {
      shallowMount(VueRenderWarningsComponent, { propsData: { readUndefinedProperty: true } });

      const [call, ...rest] = getConsoleCalls();

      expect(rest).toEqual([]);
      expect(call.args[0]).toContain('notDefinedAnywhere');
    });
  });

  describe('when a template reads runWithContext', () => {
    it('is ignored under Vue 3, since Pinia expects this property to be missing there', () => {
      shallowMount(VueRenderWarningsComponent, { propsData: { readRunWithContext: true } });

      const calls = getConsoleCalls();
      if (process.env.VUE_VERSION === '3') {
        expect(calls).toEqual([]);
      } else {
        // Vue 2 never triggers this warning for Pinia's actual (non-template) access pattern, but
        // it does for a literal template read like this one, so it's expected here too.
        expect(calls).toHaveLength(1);
      }
    });
  });
});
