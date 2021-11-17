import { shallowMount } from '@vue/test-utils';
import confetti from 'canvas-confetti';
import Confetti from '~/invite_members/components/confetti.vue';

jest.mock('canvas-confetti', () => ({
  create: jest.fn(),
}));

let wrapper;

const createComponent = () => {
  wrapper = shallowMount(Confetti);
};

afterEach(() => {
  wrapper.destroy();
});

describe('Confetti', () => {
  it('initiates confetti', () => {
    const basicCannon = jest.spyOn(Confetti.methods, 'basicCannon').mockImplementation(() => {});

    createComponent();

    expect(confetti.create).toHaveBeenCalled();
    expect(basicCannon).toHaveBeenCalled();
  });
});
