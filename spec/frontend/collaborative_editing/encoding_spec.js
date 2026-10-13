import { bytesToBase64, base64ToBytes } from '~/collaborative_editing/encoding';

describe('collaborative_editing/encoding', () => {
  it('round-trips an empty payload', () => {
    expect(base64ToBytes(bytesToBase64(new Uint8Array([])))).toEqual(new Uint8Array([]));
  });

  it('round-trips arbitrary bytes, including those outside ASCII', () => {
    const bytes = new Uint8Array([0, 1, 127, 128, 200, 255]);

    expect(base64ToBytes(bytesToBase64(bytes))).toEqual(bytes);
  });

  it('round-trips a payload large enough to overflow a spread call', () => {
    const bytes = new Uint8Array(200_000).map((_, index) => index % 256);

    expect(base64ToBytes(bytesToBase64(bytes))).toEqual(bytes);
  });
});
