import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import json from 'test_fixtures/blob/notebook/basic.json';
import jsonWithWorksheet from 'test_fixtures/blob/notebook/worksheets.json';
import Notebook from '~/notebook/index.vue';

describe('Notebook component', () => {
  let vm;

  function buildComponent(notebook) {
    return mount(Notebook, {
      propsData: { notebook },
      provide: { relativeRawPath: '' },
    }).vm;
  }

  describe('without JSON', () => {
    beforeEach(() => {
      vm = buildComponent({});

      return nextTick();
    });

    it('does not render', () => {
      expect(vm.$el.tagName).toBeUndefined();
    });
  });

  describe('with JSON', () => {
    beforeEach(() => {
      vm = buildComponent(json);

      return nextTick();
    });

    it('renders cells', () => {
      expect(vm.$el.querySelectorAll('.cell').length).toBe(json.cells.length);
    });

    it('renders markdown cell', () => {
      expect(vm.$el.querySelector('.markdown')).not.toBeNull();
    });

    it('renders code cell', () => {
      expect(vm.$el.querySelector('pre')).not.toBeNull();
    });
  });

  describe('with worksheets', () => {
    beforeEach(() => {
      vm = buildComponent(jsonWithWorksheet);

      return nextTick();
    });

    it('renders cells', () => {
      expect(vm.$el.querySelectorAll('.cell').length).toBe(
        jsonWithWorksheet.worksheets[0].cells.length,
      );
    });

    it('renders markdown cell', () => {
      expect(vm.$el.querySelector('.markdown')).not.toBeNull();
    });

    it('renders code cell', () => {
      expect(vm.$el.querySelector('pre')).not.toBeNull();
    });
  });
});
