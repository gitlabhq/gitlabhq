import { shallowMount } from '@vue/test-utils';
import GraphBar from '~/branches/components/graph_bar.vue';

let vm;

function factory(propsData = {}) {
  vm = shallowMount(GraphBar, { propsData });
}

describe('Branch divergence graph bar component', () => {
  it.each`
    position   | positionClass
    ${'left'}  | ${'position-right-0'}
    ${'right'} | ${'position-left-0'}
    ${'full'}  | ${'position-left-0'}
  `(
    'sets position class as $positionClass for position $position',
    ({ position, positionClass }) => {
      factory({
        position,
        count: 10,
        maxCommits: 100,
      });

      expect(vm.find('.js-graph-bar').classes()).toContain(positionClass);
    },
  );

  it.each`
    position   | textAlignmentClass
    ${'left'}  | ${'text-right'}
    ${'right'} | ${'text-left'}
    ${'full'}  | ${'text-center'}
  `(
    'sets text alignment class as $textAlignmentClass for position $position',
    ({ position, textAlignmentClass }) => {
      factory({
        position,
        count: 10,
        maxCommits: 100,
      });

      expect(vm.find('.js-graph-count').classes()).toContain(textAlignmentClass);
    },
  );

  it.each`
    position   | roundedClass
    ${'left'}  | ${'rounded-left'}
    ${'right'} | ${'rounded-right'}
    ${'full'}  | ${'rounded'}
  `('sets rounded class as $roundedClass for position $position', ({ position, roundedClass }) => {
    factory({
      position,
      count: 10,
      maxCommits: 100,
    });

    expect(vm.find('.js-graph-bar').classes()).toContain(roundedClass);
  });

  it.each`
    count   | label
    ${100}  | ${'100'}
    ${1000} | ${'999+'}
  `('renders label as $roundedClass for $count', ({ count, label }) => {
    factory({
      position: 'left',
      count,
      maxCommits: 1000,
    });

    expect(vm.find('.js-graph-count').text()).toContain(label);
  });

  it('sets width of bar', () => {
    factory({
      position: 'left',
      count: 100,
      maxCommits: 1000,
    });

    expect(vm.find('.js-graph-bar').attributes('style')).toEqual('width: 10%;');
  });
});
