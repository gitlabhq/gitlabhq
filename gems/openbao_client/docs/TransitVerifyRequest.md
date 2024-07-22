# OpenbaoClient::TransitVerifyRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **algorithm** | **String** | Deprecated: use \&quot;hash_algorithm\&quot; instead. | [optional][default to &#39;sha2-256&#39;] |
| **batch_input** | **Array&lt;Object&gt;** | Specifies a list of items for processing. When this parameter is set, any supplied &#39;input&#39;, &#39;hmac&#39; or &#39;signature&#39; parameters will be ignored. Responses are returned in the &#39;batch_results&#39; array component of the &#39;data&#39; element of the response. Any batch output will preserve the order of the batch input | [optional] |
| **context** | **String** | Base64 encoded context for key derivation. Required if key derivation is enabled; currently only available with ed25519 keys. | [optional] |
| **hash_algorithm** | **String** | Hash algorithm to use (POST body parameter). Valid values are: * sha1 * sha2-224 * sha2-256 * sha2-384 * sha2-512 * sha3-224 * sha3-256 * sha3-384 * sha3-512 * none Defaults to \&quot;sha2-256\&quot;. Not valid for all key types. See note about none on signing path. | [optional][default to &#39;sha2-256&#39;] |
| **hmac** | **String** | The HMAC, including OpenBao header/key version | [optional] |
| **input** | **String** | The base64-encoded input data to verify | [optional] |
| **marshaling_algorithm** | **String** | The method by which to unmarshal the signature when verifying. The default is &#39;asn1&#39; which is used by openssl and X.509; can also be set to &#39;jws&#39; which is used for JWT signatures in which case the signature is also expected to be url-safe base64 encoding instead of standard base64 encoding. Currently only valid for ECDSA P-256 key types\&quot;. | [optional][default to &#39;asn1&#39;] |
| **prehashed** | **Boolean** | Set to &#39;true&#39; when the input is already hashed. If the key type is &#39;rsa-2048&#39;, &#39;rsa-3072&#39; or &#39;rsa-4096&#39;, then the algorithm used to hash the input should be indicated by the &#39;algorithm&#39; parameter. | [optional] |
| **salt_length** | **String** | The salt length used to sign. Currently only applies to the RSA PSS signature scheme. Options are &#39;auto&#39; (the default used by Golang, causing the salt to be as large as possible when signing), &#39;hash&#39; (causes the salt length to equal the length of the hash used in the signature), or an integer between the minimum and the maximum permissible salt lengths for the given RSA key size. Defaults to &#39;auto&#39;. | [optional][default to &#39;auto&#39;] |
| **signature** | **String** | The signature, including OpenBao header/key version | [optional] |
| **signature_algorithm** | **String** | The signature algorithm to use for signature verification. Currently only applies to RSA key types. Options are &#39;pss&#39; or &#39;pkcs1v15&#39;. Defaults to &#39;pss&#39; | [optional] |
| **urlalgorithm** | **String** | Hash algorithm to use (POST URL parameter) | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TransitVerifyRequest.new(
  algorithm: null,
  batch_input: null,
  context: null,
  hash_algorithm: null,
  hmac: null,
  input: null,
  marshaling_algorithm: null,
  prehashed: null,
  salt_length: null,
  signature: null,
  signature_algorithm: null,
  urlalgorithm: null
)
```

