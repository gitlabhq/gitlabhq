import { base64ToBuffer, bufferToBase64 } from '~/authentication/webauthn/util';

const encodedString = 'SGVsbG8gd29ybGQh';
const stringBytes = [72, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100, 33];

describe('Webauthn utils', () => {
  it('base64ToBuffer', () => {
    const toArray = (val) => new Uint8Array(val);

    expect(base64ToBuffer(encodedString)).toBeInstanceOf(ArrayBuffer);

    expect(toArray(base64ToBuffer(encodedString))).toEqual(toArray(stringBytes));
  });

  it('bufferToBase64', () => {
    const buffer = base64ToBuffer(encodedString);
    expect(bufferToBase64(buffer)).toBe(encodedString);
  });
});
