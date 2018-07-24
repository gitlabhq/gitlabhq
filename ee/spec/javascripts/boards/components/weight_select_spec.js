import Vue from 'vue';
import WeightSelect from 'ee/boards/components/weight_select.vue';
import IssuableContext from '~/issuable_context';

let vm;
let board;
const weights = ['Any Weight', 'No Weight', 1, 2, 3];

function getSelectedText() {
  return vm.$el.querySelector('.value').innerText.trim();
}

function activeDropdownItem() {
  return vm.$el.querySelector('.is-active').innerText.trim();
}

describe('WeightSelect', () => {
  beforeEach((done) => {
    setFixtures('<div class="test-container"></div>');

    board = {
      weight: 0,
      labels: [],
    };

    // eslint-disable-next-line no-new
    new IssuableContext();

    const Component = Vue.extend(WeightSelect);
    vm = new Component({
      propsData: {
        board,
        canEdit: true,
        weights,
      },
    }).$mount('.test-container');

    Vue.nextTick(done);
  });

  describe('selected value', () => {
    it('defaults to Any Weight', () => {
      expect(getSelectedText()).toBe('Any Weight');
    });

    it('displays Any Weight for value -1', (done) => {
      vm.value = -1;
      Vue.nextTick(() => {
        expect(getSelectedText()).toEqual('Any Weight');
        done();
      });
    });

    it('displays No Weight', (done) => {
      vm.value = 0;
      Vue.nextTick(() => {
        expect(getSelectedText()).toEqual('No Weight');
        done();
      });
    });

    it('weight 1', (done) => {
      vm.value = 1;
      Vue.nextTick(() => {
        expect(getSelectedText()).toEqual('1');
        done();
      });
    });
  });

  describe('active item in dropdown', () => {
    it('defaults to Any Weight', (done) => {
      vm.$el.querySelector('.edit-link').click();

      setTimeout(() => {
        expect(activeDropdownItem()).toEqual('Any Weight');
        done();
      });
    });

    it('shows No Weight', (done) => {
      vm.value = 0;
      vm.$el.querySelector('.edit-link').click();

      setTimeout(() => {
        expect(activeDropdownItem()).toEqual('No Weight');
        done();
      });
    });

    it('shows correct weight', (done) => {
      vm.value = 1;
      vm.$el.querySelector('.edit-link').click();

      setTimeout(() => {
        expect(activeDropdownItem()).toEqual('1');
        done();
      });
    });
  });

  describe('changing weight', () => {
    it('sets value', (done) => {
      vm.$el.querySelector('.edit-link').click();

      setTimeout(() => {
        vm.$el.querySelectorAll('li a')[3].click();
      });

      setTimeout(() => {
        expect(activeDropdownItem()).toEqual('2');
        expect(board.weight).toEqual('2');
        done();
      });
    });

    it('sets Any Weight', (done) => {
      vm.value = 2;
      vm.$el.querySelector('.edit-link').click();

      setTimeout(() => {
        vm.$el.querySelectorAll('li a')[0].click();
      });

      setTimeout(() => {
        expect(activeDropdownItem()).toEqual('Any Weight');
        expect(board.weight).toEqual(-1);
        done();
      });
    });

    it('sets No Weight', (done) => {
      vm.value = 2;
      vm.$el.querySelector('.edit-link').click();

      setTimeout(() => {
        vm.$el.querySelectorAll('li a')[1].click();
      });

      setTimeout(() => {
        expect(activeDropdownItem()).toEqual('No Weight');
        expect(board.weight).toEqual(0);
        done();
      });
    });
  });
});
