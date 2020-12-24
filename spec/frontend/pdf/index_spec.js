import Vue from 'vue';

import { FIXTURES_PATH } from 'spec/test_constants';
import PDFLab from '~/pdf/index.vue';

jest.mock('pdfjs-dist/webpack', () => {
  return { default: jest.requireActual('pdfjs-dist/build/pdf') };
});

const pdf = `${FIXTURES_PATH}/blob/pdf/test.pdf`;

const Component = Vue.extend(PDFLab);

describe('PDF component', () => {
  let vm;

  const checkLoaded = (done) => {
    if (vm.loading) {
      setTimeout(() => {
        checkLoaded(done);
      }, 100);
    } else {
      done();
    }
  };

  describe('without PDF data', () => {
    beforeEach((done) => {
      vm = new Component({
        propsData: {
          pdf: '',
        },
      });

      vm.$mount();

      checkLoaded(done);
    });

    it('does not render', () => {
      expect(vm.$el.tagName).toBeUndefined();
    });
  });

  describe('with PDF data', () => {
    beforeEach((done) => {
      vm = new Component({
        propsData: {
          pdf,
        },
      });

      vm.$mount();

      checkLoaded(done);
    });

    it('renders pdf component', () => {
      expect(vm.$el.tagName).toBeDefined();
    });
  });
});
